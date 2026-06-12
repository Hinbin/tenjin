# Tenjin

[![CircleCI](https://circleci.com/gh/Hinbin/tenjin.svg?style=svg)](https://circleci.com/gh/Hinbin/tenjin)
[![Maintainability](https://api.codeclimate.com/v1/badges/5ae5ee384434b20e2789/maintainability)](https://codeclimate.com/github/Hinbin/tenjin/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5ae5ee384434b20e2789/test_coverage)](https://codeclimate.com/github/Hinbin/tenjin/test_coverage)

Tenjin is an online quiz platform for schools. Students answer questions, earn rewards, and compete on leaderboards while teachers manage homework and classrooms.

## Features

- Quizzes that keep students engaged with revision across the curriculum.
- Homework management that reduces teacher workload.
- Sync pupil and class data from the school MIS using Wonde.

## Getting started

```bash
bin/setup
```

This installs gem and JavaScript dependencies, creates the database, and prepares the app to run.

Copy `.env.example` to `.env` and fill in the required values (database credentials, AWS keys, Wonde API tokens, OAuth credentials).

Run the app in two terminals:

```bash
bin/rails server
bin/shakapacker-dev-server
```

Background jobs (only needed when exercising async work locally):

```bash
bin/rails jobs:work
```

## Running the tests

```bash
bundle exec rspec        # Ruby
pnpm test:js             # JavaScript (Jest)
```

System specs run against a real Chrome via Cuprite; failure screenshots are saved to `tmp/screenshots/`.

## Linting

```bash
bundle exec standardrb   # Ruby
pnpm lint                # JavaScript
```
