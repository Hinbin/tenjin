class CreateQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :questions do |t|
      t.references :topic, foreign_key: true
      t.string :text
      t.string :image
      t.integer :answers_count
      t.integer :question_type
      

      t.timestamps
    end
  end
end
