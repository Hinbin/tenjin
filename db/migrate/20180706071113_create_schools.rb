class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :client_id, null: false, unique: true
      t.string :name
      t.string :token, null: false
      t.date :last_sync
      t.integer :sync_status
      t.boolean :permitted

      t.timestamps
    end
    add_index :schools, :client_id, unique: true
  end
end
