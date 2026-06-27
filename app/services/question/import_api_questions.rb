# frozen_string_literal: true

# Imports a question payload pushed by the external Question Engine through the token API.
#
# Differs from Question::ImportQuestions (the web upload path) in three ways the API needs:
#   * upserts by (external_id, topic) so re-pushing a payload updates in place, never duplicates;
#   * forces review_status: :pending and active: false so nothing reaches students before a human
#     approves it;
#   * collects per-question validation errors instead of aborting the whole batch, and never
#     renames the destination topic.
# One Import audit row is written per call.
class Question::ImportApiQuestions < ApplicationService
  include Question::ImportBuilder

  def initialize(data, topic, filename:, token_label: nil)
    super()
    @data = data
    @topic = topic
    @filename = filename
    @token_label = token_label
    @imported = 0
    @updated = 0
    @skipped = 0
    @errors = []
  end

  def call
    questions = parse
    if questions.nil?
      @errors << 'Request body must be a JSON array of questions'
    else
      questions.each { |question| import_one(question) }
    end

    record_audit
    result(success: true, imported: @imported, updated: @updated, skipped: @skipped, errors: @errors)
  end

  private

  def parse
    parsed = JSON.parse(@data)
    parsed.is_a?(Array) ? parsed : nil
  rescue JSON::ParserError
    nil
  end

  def import_one(question_hash)
    return record_error('Question must be a JSON object', question_hash) unless question_hash.is_a?(Hash)

    error = import_validation_error(question_hash)
    return record_error(error, question_hash) if error

    upsert(question_hash)
  rescue Question::ImportBuilder::Error => e
    record_error(e.message, question_hash)
  end

  # Find-or-build by (external_id, topic), then save the fresh attributes. Existing answers and
  # config are cleared first so a re-push replaces rather than accumulates; the whole step runs in
  # a savepoint so a question that fails validation leaves its prior record untouched.
  def upsert(question_hash)
    existing = find_existing(question_hash['external_id'])
    record = existing || Question.new
    saved = false

    ActiveRecord::Base.transaction(requires_new: true) do
      reset_for_reimport(record) if existing
      assign_import_attributes(record, question_hash, @topic)
      record.assign_attributes(review_status: :pending, active: false)
      saved = record.save
      raise ActiveRecord::Rollback unless saved
    end

    return record_error(record.errors.full_messages.join(', '), question_hash) unless saved

    existing ? @updated += 1 : @imported += 1
  end

  def find_existing(external_id)
    return nil if external_id.nil?

    Question.find_by(external_id:, topic: @topic)
  end

  def reset_for_reimport(record)
    record.answers.destroy_all
    record.config = {}
  end

  def record_error(message, question_hash)
    @skipped += 1
    reference = question_hash.is_a?(Hash) ? question_hash['external_id'] : nil
    @errors << (reference ? "external_id #{reference}: #{message}" : message)
  end

  def record_audit
    Import.create!(topic: @topic, filename: @filename, token_label: @token_label,
                   imported_count: @imported, updated_count: @updated,
                   skipped_count: @skipped, import_errors: @errors)
  end
end
