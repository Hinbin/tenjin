class CreateLeaderboardEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :leaderboard_entries do |t|
      t.integer :score
      t.references :user, foreign_key: true
      t.references :classroom, foreign_key: true

      t.timestamps
    end
  end
end
