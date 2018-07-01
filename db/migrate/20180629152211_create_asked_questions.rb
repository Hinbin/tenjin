class CreateAskedQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :asked_questions do |t|
      t.belongs_to :question, index: true
      t.belongs_to :quiz, index: true
      t.boolean :correct

      t.timestamps
    end
  end
end
