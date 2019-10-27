class CreateLessons < ActiveRecord::Migration[6.0]
  def change
    create_table :lessons do |t|
      t.string :url
      t.integer :category
      t.string :video_id
      t.references :topic

      t.timestamps
    end

    add_reference :questions, :lesson, foreign_key: true, null: true
  end
end
