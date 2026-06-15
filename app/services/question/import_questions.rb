# frozen_string_literal: true

class Question::ImportQuestions < ApplicationCommand
  def initialize(data:, topic:, filename:)
    @json = JSON.parse(data)
    @topic = topic
    @questions_to_import = []
    @name = filename.rpartition(".").first
  end

  def call
    if (error = import_json_questions)
      failure(error)
    else
      success(number_questions_imported: @questions_to_import.count)
    end
  end

  private

  # Returns nil on success, an error string on failure.
  def import_json_questions
    @json.each do |question|
      @question = question
      error = validate_question || build_question
      return error if error
    end

    @questions_to_import.each(&:save)
    @topic.update_attribute(:name, @name)
    nil
  end

  def build_question
    @question["answers_attributes"] = @question["answers"]
    @question = @question.except("answers")
    lesson_error = find_or_create_lesson
    return lesson_error if lesson_error

    question_to_import = Question.new(@question)
    question_to_import.topic = @topic
    question_to_import.lesson = @lesson unless @lesson.nil?

    if question_to_import.valid?
      @questions_to_import.push(question_to_import)
      return nil
    end

    format_error(question_to_import.errors.full_messages.join(", "))
  end

  def find_or_create_lesson
    @lesson = nil
    return nil if @question["lesson"].nil?

    @lesson = Lesson.find_or_create_by(title: @question["lesson"], topic: @topic)
    return format_error(@lesson.errors.full_messages.join(", ")) unless @lesson.valid?

    @question = @question.except("lesson")
    nil
  end

  def validate_question
    unless %w[question_type answers question_text].all? { |s| @question.key?(s) }
      return format_error("Question missing key")
    end

    validate_answers
  end

  def validate_answers
    answers = @question["answers"]
    return format_error("Answers for question not in array") unless answers.respond_to?(:each)

    answers.each do |a|
      return format_error("Text key missing for answer") unless a.key?("text")
    end

    nil
  end

  def format_error(message)
    "#{message}: #{@question}"
  end
end
