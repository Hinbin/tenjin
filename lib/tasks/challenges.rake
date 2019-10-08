namespace :challenges do
  desc 'Removing old challenges'
  task remove_challenges: :environment do
    Challenge::ProcessExpiredChallenges.call
  end

  desc 'Add new challenges'
  task add_challenges: :environment do
    # Should be checked hourly
    today = Date.current
    hour = Time.current.hour
    Challenge::AddNewChallenges.call if (today.monday? || today.wednesday?) && hour == 8
    Challenge::AddNewChallenges.call(duration: 66.hours, multiplier: 2) if today.friday? && hour == 14
  end
end
