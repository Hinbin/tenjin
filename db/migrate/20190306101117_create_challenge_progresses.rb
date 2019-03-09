class CreateChallengeProgresses < ActiveRecord::Migration[5.2]
  def change
    create_table :challenge_progresses do |t|
      t.references :challenge, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :progress
      t.boolean :completed

      t.timestamps
    end
  end
end
