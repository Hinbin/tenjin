class AddActiveToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :disabled, :boolean
  end
end
