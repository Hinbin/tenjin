namespace :weekly_reset do
  desc 'Resetting weekly leaderboard'
  task leaderboard: :environment do
    Leaderboard::ResetWeeklyLeaderboard.new.call
  end
end
