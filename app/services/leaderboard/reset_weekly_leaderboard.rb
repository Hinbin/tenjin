# frozen_string_literal: true

class Leaderboard::ResetWeeklyLeaderboard < ApplicationService
  def call
    ClassroomWinner.destroy_all
    update_classroom_winners
    create_leaderboard_awards
    copy_points_to_all_time_scores
    reset_weekly_leaderboard_tables
  end

  protected

  def update_classroom_winners
    School.find_each do |sc|
      Classroom.where(school: sc).where.not(subject: nil).find_each do |c|
        top = build_leaderboard_for_subject(c.subject.name, sc.id)
        top = filter_by_classroom_name(top, c)

        next unless top.present?

        create_winners_for_top_scoring_students(top, c)
      end
    end
  end

  def build_leaderboard_for_subject(subject_name, school_id)
    Leaderboard::BuildLeaderboard.call(nil, id: subject_name, school: school_id).sort_by { |s| -s[:score] }
  end

  def filter_by_classroom_name(leaderboard, classroom)
    leaderboard.select do |elem|
      next if elem[:classroom_names].blank?

      elem[:classroom_names].include? classroom.name
    end
  end

  def create_winners_for_top_scoring_students(leaderboard, classroom)
    top_score = leaderboard[0].score
    i = 0
    while leaderboard[i].present? && leaderboard[i].score == top_score
      user_id = leaderboard[i][:id]
      ClassroomWinner.create(classroom: classroom, user: User.find(user_id), score: top_score)
      i += 1
    end
  end

  def create_leaderboard_awards
    School.find_each do |sc|
      Subject.find_each do |su|
        top = build_leaderboard_for_subject(su.name, sc.id)
        next unless top.present?

        create_awards_for_top_scoring_students(top, su, sc)
      end
    end
  end

  def create_awards_for_top_scoring_students(leaderboard, subject, school)
    top_score = leaderboard[0].score
    i = 0
    while leaderboard[i].present? && leaderboard[i].score == top_score
      LeaderboardAward.create(school: school, subject: subject, user: leaderboard[i])
      i += 1
    end
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
