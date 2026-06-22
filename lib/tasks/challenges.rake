# frozen_string_literal: true

namespace :challenges do
  desc 'Removing old challenges'
  task remove_challenges: :environment do
    Challenge::ProcessExpiredChallenges.call
  end

  desc 'Add new challenges'
  task add_challenges: :environment do
    # Should be checked hourly.
    today = Date.current
    hour = Time.current.hour

    # Clear out anything that has rotated out, so the floor top-up below counts only live challenges.
    Challenge::ProcessExpiredChallenges.call

    Challenge::AddNewChallenges.call if (today.monday? || today.wednesday?) && hour == 8
    Challenge::AddNewChallenges.call(duration: 66.hours, multiplier: 2) if today.friday? && hour == 14

    next unless hour == 8

    # Daily rotation + guarantee every subject offers at least three distinct challenges.
    Challenge::AddNewChallenges.call(duration: 1.day, daily: true)
    Challenge::EnsureSubjectChallenges.call
  end
end
