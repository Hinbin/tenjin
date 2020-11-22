class AddPurchasableToCustomisation < ActiveRecord::Migration[6.0]
  def change
    add_column :customisations, :purchasable, :boolean, default: true, null: false
  end
end
