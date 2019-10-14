# frozen_string_literal: true

class Leaderboard::ResetWeeklyLeaderboard < ApplicationService
  def initialize; end

  def call
    update_classroom_winners
    create_leaderboard_awards
    copy_points_to_all_time_scores
    reset_weekly_leaderboard_tables
  end

  def update_classroom_winners
    ClassroomWinner.destroy_all

    School.all.each do |sc|
      classrooms = Classroom.where(school: sc).where.not(subject: nil)
      classrooms.each do |c|
        top = Leaderboard::BuildLeaderboard.call(nil, id: c.subject.name, school: sc.id).sort_by { |s| -s[:score] }
        top = top.select do |elem|
          next if elem[:classroom_names].blank?

          elem[:classroom_names].include? c.name
        end

        next unless top.present?

        top_score = top[0].score
        i = 0
        while top[i].present? && top[i].score == top_score
          user_id = top[i][:id]
          ClassroomWinner.create(classroom: c, user: User.find(user_id), score: top_score)
          i += 1
        end
      end
    end
  end

  def create_leaderboard_awards
    School.all.each do |sc|
      Subject.all.each do |su|
        top = Leaderboard::BuildLeaderboard.call(nil, id: su.name, school: sc.id).sort_by { |s| -s[:score] }
        next unless top.present?

        top_score = top[0].score
        i = 0
        while top[i].present? && top[i].score == top_score
          LeaderboardAward.create(school: sc, subject: su, user: top[i])
          i += 1
        end
      end
    end
  end

  def copy_points_to_all_time_scores
    TopicScore.all.each do |ts|
      atts = AllTimeTopicScore.where(user: ts.user, topic: ts.topic).first_or_initialize
      atts.score = (atts.new_record? ? ts.score : atts.score + ts.score)
      atts.save!
    end
  end

  def reset_weekly_leaderboard_tables
    TopicScore.destroy_all
  end
end
