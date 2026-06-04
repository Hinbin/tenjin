# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Tenjin is a Rails 7 quiz and homework platform for schools. Students answer questions, earn leaderboard points, and complete homework. Teachers manage classrooms, subjects, topics, and questions.

## Commands

```sh
# Setup
bundle install
yarn install
bin/rails db:create db:schema:load

# Development server (Rails + yarn build --watch)
bin/dev

# Tests
bundle exec rspec                                    # full suite
bundle exec rspec spec/path/to/file_spec.rb          # single file
bundle exec parallel_rspec spec/                     # parallel full run across cores
bin/rails parallel:prepare                           # (re)build parallel test DBs

# Linting
bundle exec rubocop
bundle exec reek
yarn build                                           # JS asset compilation (no JS test runner)

# Before CI-style runs
bin/rails webpacker:compile
bin/rails db:create db:schema:load
bundle exec rspec
```

When running commands from Codex Desktop, PowerShell, or another non-interactive WSL entrypoint, Ruby may look unavailable unless the local `rbenv` shims are loaded. Use an interactive login shell:

```sh
wsl -e bash -lic "cd /home/nhoulton/source/tenjin && bundle exec rails runner 'puts Rails.env'"
```

Known local Ruby paths:

- Ruby shim: `/home/nhoulton/.rbenv/shims/ruby`
- Bundler shim: `/home/nhoulton/.rbenv/shims/bundle`
- Verified local Ruby: `3.4.9`
- Verified local Bundler: `2.6.9`

## Architecture

**Ruby/Rails stack:** Rails 7.2, PostgreSQL (`csquiz_development` / `csquiz_test`), Puma, Delayed Job for background work, Active Storage on S3 in production, Devise + Pundit + Rolify for auth/authz.

**Frontend:** Shakapacker (Webpack 5) bundles JS. Mix of React components (in `app/javascript/components/`), Stimulus controllers, Turbo, and Bootstrap 4 + jQuery-era libs. Match nearby patterns rather than introducing a new frontend architecture for small changes.

**Service objects** under `app/services/<domain>/` encapsulate multi-step workflows. All inherit from `ApplicationService` which provides a `.call` class method. Use service objects for domain logic; keep controllers thin.

**Authorization:** Pundit policies in `app/policies/`. Every controller action that restricts access should go through a policy.

**Authentication:** Devise with username-or-email login, plus OmniAuth for Wonde (school SSO) and Google OAuth2. The `omniauth-wonde` gem is a local path gem at `omniauth-wonde/`.

**User roles** (via rolify): `student`, `employee`, `contact`, `school_admin`. Role checks appear throughout policies and controllers.

**Background jobs:** Delayed Job. Keep web and worker behavior compatible; do not introduce ActiveJob backends without aligning with the existing DJ setup.

## Environment & Deployment

- Ruby: `3.4.9` in Gemfile; `.ruby-version` may lag — check both before changing Ruby.
- Deploy target: Heroku (`heroku-24` stack, Ubuntu 24.04). `Procfile` runs `db:migrate` on release, Puma for web, `rails jobs:work` for worker.
- Production secrets via Rails encrypted credentials (`config/credentials.yml.enc`). Env vars: `AWS_S3_BUCKET`, `DEFAULT_MAIL_SENDER`, `DEFAULT_HOST`, `RAILS_MAX_THREADS`, `WEB_CONCURRENCY`, `PORT`.
- When changing Ruby, gems, buildpacks, or native extensions: verify `heroku-24` compatibility and keep Gemfile, Gemfile.lock, `.ruby-version`, and CircleCI images in sync.

## Testing

- RSpec with FactoryBot, Devise helpers, WebMock, and VCR.
- WebMock blocks external network calls (except localhost). New HTTP calls require a VCR cassette under `spec/fixtures/vcr_cassettes/`.
- System specs use headless Chrome (Selenium/Capybara). CI retries JS examples up to 3 times; browser screenshots saved to `tmp/screenshots`.
- JavaScript console errors in system specs can fail tests — see `spec/rails_helper.rb` for any ignored patterns.

## Style

- RuboCop (`.rubocop.yml`) with new cops enabled; Reek (`config.reek`) for code smells.
- ESLint extends `standard` (`.eslintrc.js`).
- Views use Slim templates.
- `frozen_string_literal: true` at top of all Ruby files.
