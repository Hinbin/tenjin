# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Overview

Tenjin is a Ruby on Rails quiz and homework platform for schools. The public GitHub repository is `Hinbin/tenjin`, described as an online quiz platform for students to answer questions, complete homework, earn rewards, and compete on leaderboards. The repo is public, MIT licensed, and the GitHub page links to the Heroku app at `https://tenjin.herokuapp.com`.

The app is a Rails 7 codebase with PostgreSQL, RSpec, Slim views, Pundit policies, Devise authentication, Wonde OAuth/integration code, Delayed Job workers, Active Storage on S3 in production, and JavaScript assets built through Webpack/Shakapacker with React components.

## Repository Layout

- `app/models`, `app/controllers`, `app/views`, `app/helpers`, `app/mailers`: standard Rails application code.
- `app/services`: domain service objects, grouped by feature area such as `quiz`, `school`, `leaderboard`, `homework`, and `challenge`.
- `app/policies`: Pundit authorization policies.
- `app/javascript`: JavaScript, React, stores/actions, Stimulus controllers, and packs.
- `app/assets`, `app/styles`: Rails asset and stylesheet files.
- `app/jobs`: background jobs.
- `config`: Rails configuration, routes, environments, database, storage, Puma, and Shakapacker/Webpacker config.
- `db/migrate`: database migrations.
- `spec`: RSpec tests, factories, and support helpers.
- `omniauth-wonde`: local path gem used by the main app.
- `.circleci/config.yml`: current CI pipeline.
- `Procfile`: Heroku process definitions.

## Environment

- Ruby version is declared as `~> 3.2.2` in `Gemfile`.
- CircleCI uses `cimg/ruby:3.2.2-browsers`.
- `.ruby-version` currently says `3.1.1`; be aware of this mismatch before changing Ruby, Bundler, or lockfiles.
- Database is PostgreSQL. Local development uses `csquiz_development`; tests use `csquiz_test`.
- CI uses Postgres `10.9` with `PGUSER=root`, `PGHOST=127.0.0.1`, and `RAILS_ENV=test`.
- System packages in `Aptfile` include GLib and Poppler libraries. CI also installs `libvips` and `libvips-dev`.
- Browser/system tests depend on Chrome and ChromeDriver.

## Heroku Stack Policy

Tenjin is deployed on Heroku and must always remain compatible with Heroku's latest supported default stack. As of May 2026, Heroku's current default stack for newly created Cedar apps, and the default base image for Fir apps, is `heroku-24`.

When changing Ruby, Bundler, native gems, buildpacks, system packages, asset compilation, or production boot behavior:

- Check the current Heroku default stack in the official Heroku Dev Center before making assumptions. Do not hard-code today's stack as permanent future truth.
- Treat `heroku-24` compatibility as the baseline until Heroku's default moves forward.
- Prefer Ruby versions that Heroku currently supports on the default stack. Heroku's Ruby support follows Ruby Core support policy, and older Ruby patch releases may remain installable but unsupported.
- Keep `Gemfile`, `Gemfile.lock`, `.ruby-version`, CircleCI images, and Heroku runtime expectations aligned where possible. If they cannot be aligned in a single change, call out the mismatch clearly in the PR or final summary.
- Ruby upgrades can cascade into gem compatibility problems, especially gems with native extensions or Rails/Ruby version constraints. Upgrade incrementally: one Ruby, Rails, Bundler, buildpack, or major gem axis at a time.
- After Ruby or stack-related changes, verify at least `bundle install`, `yarn install`, `bin/rails webpacker:compile`, `bin/rails db:schema:load`, and the relevant RSpec coverage.
- For native dependencies, remember that Heroku-24 is based on Ubuntu 24.04 and has different build/runtime package availability than older stacks. Build-time tools may not exist at runtime.
- If using `app.json` for Review Apps or Heroku CI in the future, specify the current stack there as well so review/test apps match production.

Useful Heroku references:

- `https://devcenter.heroku.com/articles/heroku-24-stack`
- `https://devcenter.heroku.com/articles/stack`
- `https://devcenter.heroku.com/articles/ruby-support`

## Setup Commands

Use the checked-in binstubs where possible:

```sh
bundle install
yarn install
bin/rails db:create db:schema:load
```

When running Rails commands from a non-interactive WSL invocation, initialize the local `rbenv` paths first. Ruby is installed through `rbenv`, but commands such as `wsl -- bin/rails ...` may not source `~/.bashrc` and can otherwise fail with `/usr/bin/env: 'ruby': No such file or directory`.

```sh
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
bin/rails assets:precompile
```

For local development:

```sh
bin/dev
```

`Procfile.dev` starts the Rails server on port `3000` and runs `yarn build --watch`.

## Test Commands

Run the full Ruby test suite with:

```sh
bundle exec rspec
```

Run in parallel across all CPU cores (faster for local full runs):

```sh
bundle exec parallel_rspec spec/
```

Run a focused spec with:

```sh
bundle exec rspec spec/path/to/file_spec.rb
```

Before CI-style test runs, compile assets and load the schema:

```sh
bin/rails webpacker:compile
bin/rails db:create db:schema:load
bundle exec rspec
```

To (re)build the parallel test databases after schema changes:

```sh
bin/rails parallel:prepare
```

Useful targeted checks:

```sh
bundle exec rubocop
bundle exec reek
yarn build
```

There is no broad `yarn test` script in `package.json`; JavaScript verification is mainly asset compilation unless you add a test runner.

## CI

CircleCI is the active CI provider. The pipeline has `build` and `test` jobs:

- Both jobs check out the repo, install Bundler, restore/install/cache gems into `vendor/bundle`, restore/install/cache Yarn dependencies, install `libvips`, install Chrome and ChromeDriver, and print browser versions.
- The `test` job runs with parallelism `4`.
- The test job precompiles assets with `bin/rails webpacker:compile`.
- It waits for Postgres, runs `bin/rails db:create db:schema:load`, then splits `spec/**/*_spec.rb` across CircleCI nodes and runs RSpec with `RspecJunitFormatter`.
- Test results are stored from `/tmp/test-results`; browser screenshots are stored from `tmp/screenshots`.

The GitHub README also advertises Code Climate maintainability/coverage and FOSSA status badges.

## Deployment

Deployment is Heroku-style:

```procfile
release: bundle exec rails db:migrate
web: bundle exec puma -C config/puma.rb
worker: bundle exec rails jobs:work
```

Production details to keep in mind:

- The app must deploy cleanly to Heroku's latest supported default stack, currently `heroku-24`.
- Puma reads `PORT`, `RAILS_ENV`, `RAILS_MAX_THREADS`, `RAILS_MIN_THREADS`, and `WEB_CONCURRENCY`.
- `config/puma.rb` starts Barnes for Heroku runtime metrics.
- Production uses `config.active_storage.service = :amazon`; S3 bucket comes from `AWS_S3_BUCKET`.
- Production Action Cable is configured for `wss://tenjin.herokuapp.com/cable`.
- Production forces SSL.
- Background jobs use `delayed_job`; keep web and worker behavior compatible.
- Mailers depend on `DEFAULT_MAIL_SENDER`; production default URL options use `DEFAULT_HOST`.
- Rails credentials are encrypted in `config/credentials.yml.enc`; do not add secrets to the repo.

## Coding Guidelines

- Follow existing Rails conventions and keep changes close to the relevant model, controller, policy, service, view, or spec.
- Prefer service objects under `app/services/<domain>` for multi-step domain workflows.
- Use Pundit policies for authorization changes.
- Keep background work compatible with Delayed Job.
- Preserve the local `omniauth-wonde` path gem arrangement unless the task is specifically about that integration.
- Do not commit generated local artifacts such as logs, screenshots, coverage output, or `vendor/bundle`.
- Be careful with `bin/` files. They are tracked binstubs and may differ across host environments.
- The worktree may contain user edits. Do not revert unrelated changes.

## Testing Notes

- RSpec includes FactoryBot, Devise helpers, ActiveJob test helpers, WebMock, and VCR.
- WebMock blocks external network calls except localhost. VCR cassettes live under `spec/fixtures/vcr_cassettes`.
- System specs run headless Chrome through Selenium; CI retries JavaScript examples up to 3 times.
- Capybara uses Puma and increases default wait time in CI.
- JavaScript console errors in system specs can fail tests unless explicitly ignored in `spec/rails_helper.rb`.

## Style Notes

- RuboCop is configured in `.rubocop.yml`; new cops are enabled.
- Reek is configured in `config.reek`.
- ESLint extends `standard` via `.eslintrc.js`.
- Views use Slim; frontend code mixes Rails UJS/Turbo, Stimulus, React, Bootstrap 4, and jQuery-era libraries. Match nearby patterns rather than introducing a new frontend architecture for small changes.
