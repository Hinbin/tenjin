class AddDailyChallengeFlag < ActiveRecord::Migration[6.0]
  def change
    add_column :challenges, :daily, :boolean
  end
end
