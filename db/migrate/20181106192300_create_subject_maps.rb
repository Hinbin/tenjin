class CreateSubjectMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :subject_maps do |t|
      t.references :school, foreign_key: true
      t.string :client_id, unique: true, null: false
      t.string :client_subject_name, null:false
      t.references :subject, foreign_key: true

      t.timestamps
    end
  end
end
