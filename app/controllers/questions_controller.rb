# frozen_string_literal: true

class QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question, only: %i[show update destroy]

  def index
    @subjects = policy_scope(Subject).includes(:topics)
    authorize @subjects.first, :update?, policy_class: SubjectPolicy
  end

  def topic_questions
    redirect questions_path unless question_topic_params.present?

    @topic = Topic.find(question_topic_params)
    authorize @topic, :update?
    @topic_lessons = Lesson.where(topic: @topic)
    @questions = Question.clean_empty_questions(@topic)

    render 'topic_question_index'
  end

  def new
    @topic = Topic.find(new_question_params[:topic_id])
    return unless @topic.present?

    authorize @topic
    @question = Question.create(topic: @topic, question_type: 'multiple', active: true)
    Answer.create(question: @question, text: 'Click to edit this answer', correct: false)

    redirect_to @question
  end

  def show
    authorize @question.topic
    @lessons = Lesson.where(topic: @question.topic)
  end

  def update
    authorize @question.topic
    @question.update(question_update_params)
    @question.save unless @question.question_text.to_plain_text.blank?

    if request.xhr?
      head :ok
    else
      redirect_to @question
    end
  end

  def destroy
    authorize @question.topic
    redirect_to topic_questions_questions_path(topic_id: @question.topic)

    @question.update_attribute(:active, false)
  end

  private

  def question_topic_params
    params.require(:topic_id)
  end

  def question_update_params
    params.require(:question).permit(:question_text, :question_type, :lesson_id)
  end

  def set_question
    @question = Question.find(params[:id])
  end

  def new_question_params
    params.require(:topic).permit(:topic_id)
  end
end
