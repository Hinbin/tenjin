# frozen_string_literal: true

class CreateTopicPercentiles < ActiveRecord::Migration[8.1]
  def change
    create_table :topic_percentiles do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :topic, null: false, foreign_key: true
      t.integer :percentile, null: false, default: 0
      t.timestamps
    end

    # Serves the dashboard read (user + topics) and enforces one row per user/topic.
    add_index :topic_percentiles, %i[user_id topic_id], unique: true
  end
end
