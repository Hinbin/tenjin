class AddClassroomCounterCache < ActiveRecord::Migration[6.0]
  def change
    add_column :classrooms, :enrollments_count, :integer
    Classroom.find_each do |classroom|
      Classroom.reset_counters(classroom.id, :enrollments)
    end
  end
end