class RemoveLessonUrl < ActiveRecord::Migration[6.0]
  def change
    remove_column :lessons, :url, :string
  end

end
