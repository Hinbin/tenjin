# frozen_string_literal: true

class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :filename
      t.string :token_label
      t.integer :imported_count, default: 0, null: false
      t.integer :updated_count, default: 0, null: false
      t.integer :skipped_count, default: 0, null: false
      t.jsonb :import_errors, default: [], null: false

      t.timestamps
    end
  end
end
