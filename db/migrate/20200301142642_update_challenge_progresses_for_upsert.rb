class UpdateChallengeProgressesForUpsert < ActiveRecord::Migration[6.0]
  def change
    change_table :challenge_progresses, bulk: true do |t|
      t.change_default :progress, from: nil, to: 0
      t.change_default :completed, from: nil, to: false
      t.index %i[user_id challenge_id], unique: true
      t.remove_index :user_id
    end

    change_column_null :challenge_progresses, :user_id, false
    change_column_null :challenge_progresses, :challenge_id, false
    change_column_null :challenge_progresses, :progress, false

    reversible do |dir|
      dir.up do
        change_column_default :challenge_progresses, :created_at, -> { 'CURRENT_TIMESTAMP' }
      end

      dir.down do
        change_column_default :challenge_progresses, :created_at, nil
      end
    end
  end
end
