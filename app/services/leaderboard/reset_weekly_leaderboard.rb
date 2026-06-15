# frozen_string_literal: true

class Leaderboard::ResetWeeklyLeaderboard < ApplicationService
  def call
    ClassroomWinner.destroy_all
    process_all_schools
    copy_points_to_all_time_scores
    reset_weekly_leaderboard_tables
  end

  private

  def process_all_schools
    School.find_each do |school|
      Subject.find_each do |subject|
        leaderboard = build_leaderboard(school, subject)
        next if leaderboard.blank?

        create_classroom_winners(school, subject, leaderboard)
        create_awards(school, subject, leaderboard)
      end
    end
  end

  def build_leaderboard(school, subject)
    Leaderboard::Query.new(nil, id: subject.name, school: school.id)
      .results
      .sort_by { |s| -s[:score] }
  end

  def create_classroom_winners(school, subject, leaderboard)
    Classroom.where(school: school, subject: subject).find_each do |classroom|
      top = filter_by_classroom_name(leaderboard, classroom)
      next if top.blank?

      top_score = top.first.score
      top_scorers(top).each do |entry|
        ClassroomWinner.create(classroom: classroom, user_id: entry.id, score: top_score)
      end
    end
  end

  def create_awards(school, subject, leaderboard)
    top_scorers(leaderboard).each do |entry|
      LeaderboardAward.create(school: school, subject: subject, user_id: entry.id)
    end
  end

  def filter_by_classroom_name(leaderboard, classroom)
    leaderboard.select do |elem|
      next if elem[:classroom_names].blank?

      elem[:classroom_names].include?(classroom.name)
    end
  end

  def top_scorers(leaderboard)
    top_score = leaderboard.first.score
    leaderboard.take_while { |entry| entry.score == top_score }
  end

  def copy_points_to_all_time_scores
    TopicScore.find_each do |ts|
      atts = AllTimeTopicScore.where(user: ts.user, topic: ts.topic).first_or_initialize
      atts.score = (atts.new_record? ? ts.score : atts.score + ts.score)
      atts.save!
    end
  end

  def reset_weekly_leaderboard_tables
    TopicScore.destroy_all
  end
end
