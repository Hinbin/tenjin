# frozen_string_literal: true

class AddUniqueExternalIdIndexToQuestions < ActiveRecord::Migration[8.1]
  def up
    guard_against_duplicates!

    # Partial unique index so the API can upsert by (topic, external_id). Scoped with
    # WHERE external_id IS NOT NULL because the bulk of existing rows have no external_id
    # (Postgres treats each NULL as distinct, but the partial index keeps the intent clear).
    add_index :questions, %i[topic_id external_id],
              unique: true,
              where: 'external_id IS NOT NULL',
              name: 'index_questions_on_topic_id_and_external_id'
  end

  def down
    remove_index :questions, name: 'index_questions_on_topic_id_and_external_id'
  end

  private

  def guard_against_duplicates!
    duplicates = select_all(<<~SQL.squish)
      SELECT topic_id, external_id, COUNT(*) AS n
      FROM questions
      WHERE external_id IS NOT NULL
      GROUP BY topic_id, external_id
      HAVING COUNT(*) > 1
    SQL
    return if duplicates.none?

    raise "Cannot add unique index: #{duplicates.count} (topic_id, external_id) pair(s) " \
          'already duplicated. Resolve these before migrating.'
  end
end
