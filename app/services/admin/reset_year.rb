# frozen_string_literal: true

class Admin::ResetYear < ApplicationService
  def initialize; end

  def call
    remove_topic_scores
    remove_homeworks
    remove_enrollments
    remove_classrooms
    remove_challenges
    remove_leaderboard_awards
  end

  private

  def remove_topic_scores
    TopicScore.destroy_all
    AllTimeTopicScore.destroy_all
  end

  def remove_homeworks
    HomeworkProgress.destroy_all
    Homework.destroy_all
  end

  def remove_enrollments
    Enrollment.destroy_all
  end

  def remove_classrooms
    ClassroomWinner.destroy_all
    Classroom.destroy_all
  end

  def remove_challenges
    ChallengeProgress.destroy_all
    Challenge.destroy_all
  end

  def remove_leaderboard_awards
    LeaderboardAward.destroy_all
  end
end
