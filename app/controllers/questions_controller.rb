# frozen_string_literal: true

class QuestionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @subjects = policy_scope(Subject.with_role(:question_author, current_user).where(active: true))
      .includes(topics: :questions)
    raise Pundit::NotAuthorizedError if @subjects.blank?
  end

  def topic
    redirect_to questions_path if topic_params.blank?

    @topic = Topic.find(topic_params)
    authorize @topic, :show?
    @topic_lessons = Lesson.where(topic: @topic)
    @questions = Question.with_rich_text_question_text_and_embeds
      .includes(:question_statistic, :lesson)
      .where(topic: @topic, active: true)

    render "topic_question_index"
  end

  def lesson
    redirect_to lessons_path if lesson_params.blank?

    @lesson = Lesson.find(lesson_params)
    authorize @lesson, :view_questions?
    @questions = Question.with_rich_text_question_text_and_embeds
      .includes(:answers)
      .where(lesson: @lesson, active: true)

    render "lesson_question_index"
  end

  def reset_flags
    question = find_question
    authorize question, :update?
    FlaggedQuestion.where(question: question).delete_all
    Question.reset_counters question.id, :flagged_questions_count
    redirect_to question
  end

  def flagged_questions
    @subject = Subject.find(flagged_questions_params)
    authorize @subject, :flagged_questions?
    @questions = @subject.flagged_questions
    render :flagged
  end

  def show
    @question = find_question
    @question.assign_attributes(question_params) if params[:question].present?
    authorize @question
    check_answers(@question)
  end

  def new
    @question = Question.new(question_params)
    authorize @question

    return if @question.topic.blank?

    check_answers(@question)
  end

  def create
    @question = Question.new(question_params)
    authorize @question
    check_answers(@question)

    if @question.save
      redirect_to topic_questions_path(topic_id: @question.topic), notice: "Question successfully created"
    else
      render :new
    end
  end

  def update
    @question = find_question
    @question.assign_attributes(question_params)
    authorize @question
    check_answers(@question)

    if @question.save
      redirect_to @question, notice: "Question successfully updated"
    else
      render :show
    end
  end

  def destroy
    question = authorize find_question
    topic = question.topic
    question.update_attribute(:active, false)
    redirect_to topic_questions_path(topic_id: topic)
  end

  def download_topic
    topic = Topic.find(topic_params)
    authorize topic, :show?
    questions = Question.where(topic: topic).to_json(include: :answers)

    send_data questions,
      type: "application/json; header=present",
      disposition: "attachment; filename=#{topic.name}.json"
  end

  def import_topic
    @topic = Topic.find(topic_params)
    authorize @topic, :update?
  end

  def import
    @topic = Topic.find(topic_params)
    authorize @topic, :update?

    if params[:file].nil?
      flash[:alert] = "Please attach a file"
      return render :import_topic, topic_id: @topic
    end

    data = params[:file].read
    result = Question::ImportQuestions.call(data, @topic, params[:file].original_filename)
    flash[:notice] = result.error
    redirect_to topic_questions_path(topic_id: @topic)
  end

  private

  def topic_params
    params.require(:topic_id)
  end

  def lesson_params
    params.require(:lesson_id)
  end

  def flagged_questions_params
    params.require(:subject_id)
  end

  def question_params
    params.require(:question).permit(:question_text, :question_type, :lesson_id,
      :topic_id, answers_attributes: %i[correct id text _destroy])
  end

  def find_question
    Question.find(params[:id])
  end

  def setup_boolean_question(question)
    question.answers.build until question.answers.length >= 2
    question.answers = question.answers.slice(0..1) if question.answers.length > 2
    return if question.valid?

    question.answers.second.text = "True"
    question.answers.first.text = "False"
  end

  def check_answers(question)
    setup_boolean_question(question) if question.boolean?
    question.answers.each { |a| a.correct = true } if question.short_answer? || question.question_type.nil?
  end
end
