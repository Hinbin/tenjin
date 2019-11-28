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
    @questions = Question.with_rich_text_question_text_and_embeds
                         .includes(:question_statistic)
                         .where(topic: @topic, active: true)

    render 'topic_question_index'
  end

  def new
    @question = Question.new(question_params)
    authorize @question.topic

    return unless @question.topic.present?

    check_answers
    build_answers
  end

  def create
    @question = Question.new(question_params)
    authorize @question.topic
    check_answers

    if @question.save
      redirect_to topic_questions_questions_path(topic_id: @question.topic), notice: 'Question successfully created'
    else
      render :new
    end
  end

  def show
    @question.assign_attributes(question_params) if params[:question].present?
    authorize @question.topic
    check_answers
    build_answers
  end

  def update
    @question.assign_attributes(question_params)
    authorize @question.topic
    check_answers

    if @question.save
      redirect_to @question, notice: 'Question successfully updated'
    else
      render :show
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

  def question_params
    params.require(:question).permit(:question_text, :question_type, :lesson_id, :topic_id, answers_attributes: %i[correct id text _destroy])
  end

  def set_question
    @question = Question.find(params[:id])
  end

  def setup_boolean_question
    @question.answers.build until @question.answers.length >= 2
    @question.answers = @question.answers.slice(0..1) if @question.answers.length > 2
    return if @question.valid?

    @question.answers.second.text = 'True'
    @question.answers.first.text = 'False'
  end

  def check_answers
    setup_boolean_question if @question.boolean?
    @question.answers.each { |a| a.correct = true } if @question.short_answer? || @question.question_type.nil?
  end

  def build_answers
    unless @question.answers.present?
      @question.answers.build if @question.short_answer? || @question.question_type.nil?
    end

    @question.answers.build until @question.answers.length >= 4 || !@question.multiple?
  end
end
