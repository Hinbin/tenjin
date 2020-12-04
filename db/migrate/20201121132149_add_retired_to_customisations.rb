class AddRetiredToCustomisations < ActiveRecord::Migration[6.0]
  def change
    add_column :customisations, :retired, :boolean, default: false, null: false
    add_column :customisations, :sticky, :boolean, default: false, null: false
  end
end
