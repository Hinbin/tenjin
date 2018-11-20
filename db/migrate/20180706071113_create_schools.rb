class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :client_id, null: false, unique: true
      t.string :name
      t.string :token
      t.date :last_sync
      t.boolean :last_sync_successful
      t.boolean :permitted

      t.timestamps
    end
    add_index :schools, :client_id, unique: true
  end
end
