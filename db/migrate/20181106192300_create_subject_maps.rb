class CreateSubjectMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :subject_maps do |t|
      t.references :permitted_school, foreign_key: true

      t.timestamps
    end
  end
end
