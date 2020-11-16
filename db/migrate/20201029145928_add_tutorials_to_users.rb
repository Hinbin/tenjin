class AddTutorialsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :tutorials, :integer, default: 0, null: false
  end
end
