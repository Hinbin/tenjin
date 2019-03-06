namespace :challenges do
  desc 'Removing old challenges'
  task remove_challenges: :environment do
    Challenge::ProcessExpiredChallenges.new().call
  end

  desc 'Add new challenges'
  task add_challenges: :environment do
    Challenge.add_new_challenges
  end
end
