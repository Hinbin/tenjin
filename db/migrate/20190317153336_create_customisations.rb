class CreateCustomisations < ActiveRecord::Migration[6.0]
  def change
    create_table :customisations do |t|
      t.integer :customisation_type
      t.integer :cost
      t.string :name
      t.string :value

      t.timestamps
    end
  end
end
