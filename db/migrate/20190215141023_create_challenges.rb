class CreateChallenges < ActiveRecord::Migration[5.2]
  def change
    create_table :challenges do |t|
      t.integer :challenge_type
      t.datetime :start_date
      t.datetime :end_date
      t.integer :points
      t.references :topic, foreign_key: true

      t.timestamps
    end
  end
end
