# frozen_string_literal: true

# Review queue for questions imported through the API. They arrive pending + inactive; an
# authorised question author approves them (making them live for students) or rejects them.
class QuestionReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question, only: %i[approve reject]

  # Pending questions are scoped by hand to the subjects the author owns; index and approve_all are
  # exempt from verify_authorized, so there is no policy_scope to verify here. The same scoping is
  # exactly the set QuestionPolicy#update? would allow, so bulk approval over it is safe.
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :approve_all

  def index
    @questions_by_topic = pending_authored_questions
                          .includes(:topic, :answers, :rich_text_question_text)
                          .order('topics.name')
                          .group_by(&:topic)
  end

  def approve_all
    count = pending_authored_questions.count
    pending_authored_questions.find_each(&:approve!)
    redirect_to question_reviews_path, notice: "#{count} #{'question'.pluralize(count)} approved"
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

  def pending_authored_questions
    Question.pending
            .joins(topic: :subject)
            .where(subjects: { id: authored_subject_ids })
  end

  def authored_subject_ids
    Subject.with_role(:question_author, current_user).pluck(:id)
  end
end
