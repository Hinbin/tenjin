# syntax=docker/dockerfile:1
# check=error=true

# Production image for Tenjin. Built and run on Render (or any Docker host).
# For local development use `bin/dev`, not this image.

# Pin to bookworm so apt package names stay stable (libvips42, libpoppler-glib8).
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim-bookworm AS base

# Rails app lives here
WORKDIR /rails

# Runtime packages:
#   libvips42        -> ruby-vips / image_processing
#   libpoppler-glib8 -> PDF thumbnailing
#   postgresql-client -> pg gem + rails db tasks
#   libjemalloc2     -> better memory behaviour for long-running Ruby processes
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips42 \
      libpoppler-glib8 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Production runtime defaults. DEFAULT_HOST, RAILS_MASTER_KEY, DATABASE_URL etc.
# are injected by Render at runtime.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    LD_PRELOAD="libjemalloc.so.2"

# ---- Build stage: compile gems and precompile assets -------------------------
FROM base AS build

# Packages needed only to build gems with native extensions.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libvips-dev \
      libpoppler-glib-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems. The local path gem (omniauth-wonde) is copied in first so the
# bundle install can resolve it.
COPY Gemfile Gemfile.lock ./
COPY omniauth-wonde/ omniauth-wonde/
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap for faster boots
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets (Propshaft + importmap + dartsass) without needing the real
# master key. SECRET_KEY_BASE_DUMMY lets the build run with a throwaway key.
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ---- Final stage -------------------------------------------------------------
FROM base

# Copy built gems and application from the build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as an unprivileged user. Create the writable runtime dirs first since some
# (e.g. storage) are excluded by .dockerignore and won't exist after the copy.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

EXPOSE 3000

# Default command runs the web server; the worker service overrides this with
# `bundle exec bin/jobs start` (see render.yaml). Database migrations run via
# Render's pre-deploy command, not here, so web + worker never race.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
