class CreateActiveCustomisations < ActiveRecord::Migration[6.0]
  def change
    create_table :active_customisations do |t|
      t.references :customisation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :active_customisations, [:customisation_id, :user_id], unique: true
  end
end
