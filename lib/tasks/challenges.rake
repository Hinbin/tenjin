namespace :challenges do
  desc 'Removing old challenges'
  task remove_challenges: :environment do
    Challenge::ProcessExpiredChallenges.new.call
  end

  desc 'Add new challenges'
  task add_challenges: :environment do
    # Should be checked hourly
    today = Date.today
    hour = Time.now.hour
    Challenge::AddNewChallenges.new.call if (today.monday? || today.wednesday?) && hour == 8
    Challenge::AddNewChallenges.new(duration: 66.hours, multiplier: 2).call if today.friday? && hour == 14
  end
end
