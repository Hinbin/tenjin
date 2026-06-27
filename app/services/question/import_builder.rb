# frozen_string_literal: true

# Shared payload handling for the two import paths (web upload and the import API). Keeps the
# structural validation and the payload-hash -> Question assignment in one place so the API
# service does not duplicate the rules the web upload already relies on.
module Question::ImportBuilder
  # Raised when a payload references a lesson that cannot be created; carries a message the
  # caller turns into a per-question error.
  class Error < StandardError
  end

  # Returns an error message String when the payload hash is structurally invalid, else nil.
  def import_validation_error(question_hash)
    return 'Question missing key' unless %w[question_type answers question_text].all? { |key| question_hash.key?(key) }

    answers = question_hash['answers']
    return 'Answers for question not in array' unless answers.respond_to?(:each)
    return 'Text key missing for answer' if answers.any? { |answer| answer.key?('body') }

    nil
  end

  # Assigns the payload's answers, lesson and scalar columns onto `record` (new or existing)
  # for `topic`. Does not save. Raises Error when the referenced lesson is invalid.
  def assign_import_attributes(record, question_hash, topic)
    attrs = question_hash.dup
    attrs['answers_attributes'] = attrs.delete('answers')
    lesson = resolve_lesson(attrs.delete('lesson'), topic)

    record.assign_attributes(attrs)
    record.topic = topic
    record.lesson = lesson if lesson
    record
  end

  private

  def resolve_lesson(title, topic)
    return nil if title.nil?

    lesson = Lesson.find_or_create_by(title:, topic:)
    raise Error, lesson.errors.full_messages.join(', ') unless lesson.valid?

    lesson
  end
end
