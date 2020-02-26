class UpdateTopicScoresForUpsert < ActiveRecord::Migration[6.0]
  def change
    change_table :topic_scores, bulk: true do |t|
      t.change_default :score, from: nil, to: 0
      t.index %i[user_id topic_id], unique: true
      t.remove_index :user_id
    end

    change_column_null :topic_scores, :user_id, false
    change_column_null :topic_scores, :topic_id, false
    change_column_null :topic_scores, :score, false

    reversible do |dir|
      dir.up do
        change_column_default :topic_scores, :created_at, -> { 'CURRENT_TIMESTAMP' }
      end

      dir.down do
        change_column_default :topic_scores, :created_at, nil
      end
    end
  end
end
