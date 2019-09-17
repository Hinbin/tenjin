class CreateLeaderboardAwards < ActiveRecord::Migration[6.0]
  def change
    create_table :leaderboard_awards do |t|

      t.references :subject, foreign_key: true
      t.references :user, foreign_key: true
      t.references :school, foreign_key: true

      t.timestamps
    end
  end
end