# frozen_string_literal: true

# The boolean question type is retired: a True/False question is structurally a two-answer MCQ, so
# existing rows are remapped from question_type 1 (boolean) to 2 (multiple). Slot 1 is left unused.
class ConvertBooleanQuestionsToMultiple < ActiveRecord::Migration[8.0]
  def up
    execute 'UPDATE questions SET question_type = 2 WHERE question_type = 1'
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'boolean questions cannot be distinguished from other multiple-choice questions after conversion'
  end
end
