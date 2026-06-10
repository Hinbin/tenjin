# frozen_string_literal: true

HireFire::Resource.configure do |config|
  config.dyno(:worker) do
    SolidQueue::Job.where(finished_at: nil).count
  end
end