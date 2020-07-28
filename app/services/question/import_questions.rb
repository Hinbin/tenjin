# frozen_string_literal: true

class Question::ImportQuestions < ApplicationService
  def initialize(json, topic)
    @json = json
    @topic = topic
  end

  def call
    import_json_questions
  end

  private

  def import_json_questions
  end
end
