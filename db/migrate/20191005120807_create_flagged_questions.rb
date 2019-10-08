class CreateFlaggedQuestions < ActiveRecord::Migration[6.0]
  def change
    create_table :flagged_questions do |t|
      t.references :question, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
