class CreateClassrooms < ActiveRecord::Migration[5.2]
  def change
    create_table :classrooms do |t|
      t.string :client_id, null: false, unique: true
      t.string :name, null: false
      t.string :code
      t.string :description
      t.boolean :disabled
      t.belongs_to :subject, index: true
      t.belongs_to :school, index: true

      t.timestamps
    end
  end
end
