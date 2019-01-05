class CreateTopicScores < ActiveRecord::Migration[5.2]
  def change
    create_table :topic_scores do |t|
      t.integer :score
      t.references :user, foreign_key: true
      t.references :topic, foreign_key: true

      t.timestamps
    end

    add_index :topic_scores, [:user, :topic], unique: true
  end
end
