class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :clientID    

      t.timestamps
    end
    add_index :schools, :clientID, unique: true
  end
end
