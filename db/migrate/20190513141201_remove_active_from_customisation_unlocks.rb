class RemoveActiveFromCustomisationUnlocks < ActiveRecord::Migration[6.0]
  def change
    remove_column :customisation_unlocks, :active
  end
end
