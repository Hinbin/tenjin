class CreateSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions do |t|
      t.references :questionsAsked, array: true, default: []
      t.datetime :timeAsked
      t.integer :streak
      t.integer :answeredCorrect
      t.integer :numQuestionsAsked
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
