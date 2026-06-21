# frozen_string_literal: true

class QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question, only: %i[show update destroy reset_flags]

  def lesson
    redirect lessons_path unless lesson_params.present?

    @lesson = Lesson.find(lesson_params)
    authorize @lesson, :view_questions?
    @questions = Question.with_rich_text_question_text_and_embeds
                         .includes(:answers)
                         .where(lesson: @lesson, active: true)

    render 'lesson_question_index'
  end

  def show
    @question.assign_attributes(question_params) if params[:question].present?
    authorize @question
    check_answers
    # build_answers
  end

  def new
    @question = Question.new(question_params)
    authorize @question

    return unless @question.topic.present?

    check_answers
  end

  def create
    @question = Question.new(question_params)
    authorize @question
    check_answers

    if @question.save
      redirect_to topic_path(@question.topic), notice: 'Question successfully created'
    else
      render :new
    end
  end

  def update
    @question.assign_attributes(question_params)
    authorize @question
    check_answers

    if @question.save
      redirect_to @question, notice: 'Question successfully updated'
    else
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    authorize @question
    redirect_to topic_path(@question.topic)

    @question.update_attribute(:active, false)
  end

  def download_topic
    @topic = Topic.find(topic_params)
    authorize @topic, :show?
    @questions = Question.where(topic: @topic).to_json(include: :answers)

    send_data @questions,
              type: 'application/json; header=present',
              disposition: "attachment; filename=#{@topic.name}.json"
  end

  def import_topic
    @topic = Topic.find(topic_params)
    authorize @topic, :update?
  end

  def import
    @topic = Topic.find(topic_params)
    authorize @topic, :update?

    if params[:file].nil?
      flash[:alert] = 'Please attach a file'
      return redirect_to import_topic_questions_path(topic_id: @topic)
    end

    data = File.read(params[:file])
    result = Question::ImportQuestions.call(data, @topic, params.expect(:file).original_filename)
    flash[:notice] = result.error unless result.success?
    redirect_to topic_path(@topic)
  end

  def reset_flags
    authorize current_user, :update?
    FlaggedQuestion.where(question: @question).delete_all
    Question.reset_counters @question.id, :flagged_questions_count
    redirect_to @question
  end

  private

  def topic_params
    params.require(:topic_id)
  end

  def lesson_params
    params.require(:lesson_id)
  end

  def question_params
    params.expect(question: [:question_text, :question_type, :lesson_id,
                             :topic_id, { answers_attributes: [%i[correct id text _destroy]] }])
  end

  def set_question
    @question = Question.find(params.expect(:id))
  end

  def setup_boolean_question
    @question.answers.build until @question.answers.length >= 2
    @question.answers = @question.answers.slice(0..1) if @question.answers.length > 2
    return if @question.valid?

    @question.answers.second.text = 'True'
    @question.answers.first.text = 'False'
  end

  def check_answers
    apply_structured_config
    setup_boolean_question if @question.boolean?
    @question.answers.each { |a| a.correct = true } if @question.short_answer? || @question.question_type.nil?
  end

  # The structured-question builder posts its content as a JSON string in question[config]; parse it
  # onto the jsonb column (a String would be stored as a JSON scalar, not the structure we want).
  def apply_structured_config
    config = parsed_config
    @question.config = config unless config.nil?
  end

  def parsed_config
    raw = params.dig(:question, :config)
    return nil if raw.blank?

    raw.is_a?(String) ? JSON.parse(raw) : raw.to_unsafe_h
  rescue JSON::ParserError
    nil
  end

  def build_answers
    @question.answers.build if !@question.answers.present? && (@question.short_answer? || @question.question_type.nil?)

    @question.answers.build until @question.answers.length >= 4 || !@question.multiple?
  end
end
