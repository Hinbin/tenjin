namespace :weekly_reset do
  desc 'Resetting weekly leaderboard'
  task leaderboard: :environment do
    today = Date.current
    Leaderboard::ResetWeeklyLeaderboard.new.call if today.sunday?
  end
end
