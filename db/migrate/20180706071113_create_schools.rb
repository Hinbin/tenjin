class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :client_id   

      t.timestamps
    end
    add_index :schools, :client_id, unique: true
  end
end
