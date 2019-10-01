class CreateClassroomWinners < ActiveRecord::Migration[6.0]
  def change
    create_table :classroom_winners do |t|
      t.references :user, foreign_key: true
      t.references :classroom, foreign_key: true
      t.integer :score

      t.timestamps
    end
  end
end
