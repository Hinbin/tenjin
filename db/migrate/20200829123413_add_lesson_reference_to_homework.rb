class AddLessonReferenceToHomework < ActiveRecord::Migration[6.0]
  def change
    add_reference :homeworks, :lesson, null: true, foreign_key: true
  end
end
