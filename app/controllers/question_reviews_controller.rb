# frozen_string_literal: true

# Review queue for questions imported through the API. They arrive pending + inactive; an
# authorised question author approves them (making them live for students) or rejects them.
class QuestionReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question, only: %i[approve reject]

  # Pending questions are scoped by hand to the subjects the author owns; index is exempt from
  # verify_authorized, so there is no policy_scope to verify here.
  skip_after_action :verify_policy_scoped, only: :index

  def index
    @questions_by_topic = Question.pending
                                  .joins(topic: :subject)
                                  .where(subjects: { id: authored_subject_ids })
                                  .includes(:topic, :answers, :rich_text_question_text)
                                  .order('topics.name')
                                  .group_by(&:topic)
  end

  def approve
    authorize @question, :update?
    @question.approve!
    redirect_to question_reviews_path, notice: 'Question approved'
  end

  def reject
    authorize @question, :update?
    @question.reject!
    redirect_to question_reviews_path, notice: 'Question rejected'
  end

  private

  def set_question
    @question = Question.find(params.expect(:id))
  end

  def authored_subject_ids
    Subject.with_role(:question_author, current_user).pluck(:id)
  end
end
