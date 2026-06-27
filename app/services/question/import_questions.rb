# frozen_string_literal: true

class Question::ImportQuestions < ApplicationService
  include Question::ImportBuilder

  def initialize(data, topic, filename)
    super()
    @json = JSON.parse(data)

    @topic = topic
    @questions_to_import = []

    @name = filename.rpartition('.').first
  end

  def call
    if import_json_questions
      result(success: true, number_questions_imported: @questions_to_import.count)
    else
      result(success: false, error: @error)
    end
  end

  private

  def import_json_questions
    @json.each do |question|
      error = import_validation_error(question)
      return raise_error(error, question) if error
      return false unless build_question(question)
    end

    @questions_to_import.each(&:save)

    @topic.update_attribute(:name, @name)
    true
  end

  def build_question(question_hash)
    record = assign_import_attributes(Question.new, question_hash, @topic)

    if record.valid?
      @questions_to_import.push(record)
    else
      raise_error(record.errors.full_messages.join(', '), question_hash)
    end
  rescue Question::ImportBuilder::Error => e
    raise_error(e.message, question_hash)
  end

  def raise_error(error, question_hash)
    @error = "#{error}: #{question_hash}"
    false
  end
end
