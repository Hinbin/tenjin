# frozen_string_literal: true

class AddConfigToQuestions < ActiveRecord::Migration[8.1]
  def change
    # Structured content for richer question types (drag_drop: cloze text + items + answer map;
    # matrix: rows + columns + correct cells). Legacy types keep using the flat answers table.
    add_column :questions, :config, :jsonb, default: {}, null: false
  end
end
