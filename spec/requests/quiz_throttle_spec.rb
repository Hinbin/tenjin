# frozen_string_literal: true

require 'rails_helper'

# Anti-cheat #2: the answer endpoint is throttled per USER (never per IP), so a whole computer lab
# behind one school IP isn't mistaken for one person machine-gunning answers.
#
# We test the throttle's discriminator directly rather than over a real request: Devise's test login
# injects the user into the controller's Warden proxy, not into a session cookie, so `env['warden']`
# is empty at the middleware layer under test (it is populated in production by the real cookie).
RSpec.describe 'Rack::Attack quiz answer throttle' do
  subject(:throttle) { Rack::Attack.throttles['quiz answers per user'] }

  def request_for(path, method:, user_id: nil)
    env = Rack::MockRequest.env_for(path, method: method)
    user = user_id && instance_double(User, id: user_id)
    env['warden'] = instance_double(Warden::Proxy, user: user)
    Rack::Attack::Request.new(env)
  end

  it 'is registered with a generous per-window limit a human would not reach' do
    expect(throttle).to have_attributes(limit: 20, period: 10)
  end

  it 'keys on the authenticated user id, not the IP, so a shared school IP is irrelevant' do
    expect(throttle.block.call(request_for('/quizzes/5', method: 'PATCH', user_id: 42))).to eq(42)
  end

  it 'gives two classmates on one IP independent buckets' do
    bucket_a = throttle.block.call(request_for('/quizzes/5', method: 'PATCH', user_id: 1))
    bucket_b = throttle.block.call(request_for('/quizzes/5', method: 'PATCH', user_id: 2))
    expect(bucket_a).not_to eq(bucket_b)
  end

  it 'only watches answer submissions, not reads or other endpoints' do
    expect(throttle.block.call(request_for('/quizzes/5', method: 'GET', user_id: 42))).to be_nil
    expect(throttle.block.call(request_for('/dashboard', method: 'PATCH', user_id: 42))).to be_nil
  end

  it 'leaves unauthenticated requests alone (the route is authenticated anyway)' do
    expect(throttle.block.call(request_for('/quizzes/5', method: 'PATCH', user_id: nil))).to be_nil
  end
end
