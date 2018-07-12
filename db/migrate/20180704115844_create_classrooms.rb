class CreateClassrooms < ActiveRecord::Migration[5.2]
  def change
    create_table :classrooms do |t|
      t.string :name
      t.belongs_to :subject, index: true
      t.belongs_to :school, index: true

      t.timestamps
    end
  end
end
