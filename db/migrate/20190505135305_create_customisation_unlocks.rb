class CreateCustomisationUnlocks < ActiveRecord::Migration[6.0]
  def change
    create_table :customisation_unlocks do |t|
      t.references :customisation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
