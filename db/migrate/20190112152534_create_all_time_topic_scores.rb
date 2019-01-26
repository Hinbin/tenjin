class CreateAllTimeTopicScores < ActiveRecord::Migration[5.2]
  def change
    create_table :all_time_topic_scores do |t|
      t.integer :score
      t.references :user, foreign_key: true
      t.references :topic, foreign_key: true

      t.timestamps
    end

  end
end
