class AddClassroomCounterCache < ActiveRecord::Migration[6.0]
  def change
    add_column :classrooms, :enrollments_count, :integer
  end
end