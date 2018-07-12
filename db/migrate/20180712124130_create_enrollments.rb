class CreateEnrollments < ActiveRecord::Migration[5.2]
  def change
    create_table :enrollments do |t|
      t.references :user, foreign_key: true
      t.references :classroom, foreign_key: true
      t.integer :score

      t.timestamps
    end
  end
end
