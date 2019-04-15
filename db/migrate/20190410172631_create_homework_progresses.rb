class CreateHomeworkProgresses < ActiveRecord::Migration[6.0]
  def change
    create_table :homework_progresses do |t|
      t.references :homework, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :progress
      t.boolean :completed

      t.timestamps
    end
  end
end
