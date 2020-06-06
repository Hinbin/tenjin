# frozen_string_literal: true

class AdjustUserStatisticsDefaults < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        change_column(:user_statistics, :week_beginning, :date, null: false)
      end

      dir.down do
        change_column(:user_statistics, :week_beginning, :datetime, null: true)
      end
    end

    change_column_default(:user_statistics, :questions_answered, from: nil, to: 0)
    change_column_null(:user_statistics, :questions_answered, false, 0)
  end
end
