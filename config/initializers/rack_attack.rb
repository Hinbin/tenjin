# frozen_string_literal: true

# Anti-cheat throttle for quiz answer submissions (PUT/PATCH /quizzes/:id).
#
# Keyed on the authenticated USER, never the IP. A whole computer lab sits behind one school NAT/public
# IP, so an IP throttle would treat 30 students answering normally as one machine and lock the class
# out. Per-user keying gives every student an isolated bucket: classmates never collide, but a single
# browser extension auto-answering dozens of questions a second trips its own limit.
#
# This is one layer only — Quiz::CheckAnswer's minimum-answer-time floor and the flagged_fast teacher
# view are the others. The limit is generous so a fast human never hits it; it exists to stop machine-
# speed flooding.
class Rack::Attack
  # Own in-memory store so the throttle works regardless of the app's cache (test uses :null_store).
  # NOTE: this counter lives per process; with multiple Puma workers each holds its own tally, so a
  # shared store (Redis/memcached/solid_cache) is the upgrade if/when the app runs multi-process.
  cache.store = ActiveSupport::Cache::MemoryStore.new

  ANSWER_PATH = %r{\A/quizzes/\d+\z}
  ANSWER_LIMIT = 20      # max submissions ...
  ANSWER_PERIOD = 10     # ... per this many seconds, per user

  throttle('quiz answers per user', limit: ANSWER_LIMIT, period: ANSWER_PERIOD) do |req|
    next unless (req.put? || req.patch?) && req.path.match?(ANSWER_PATH)

    # Warden user id if signed in; nil (not throttled) otherwise — the route is authenticated anyway.
    req.env['warden']&.user&.id
  end

  # Match the controller's JSON error shape so the quiz front-end can surface it gracefully.
  self.throttled_responder = lambda do |_request|
    headers = { 'Content-Type' => 'application/json' }
    body = { error: 'You are answering too quickly. Please slow down and try again.' }
    [429, headers, [body.to_json]]
  end
end

# Off by default under test so the shared in-memory counter can't accumulate across examples and trip
# unrelated specs; the throttle spec flips it on (and resets the store) for its own examples.
Rack::Attack.enabled = false if Rails.env.test?
