class CreateDefaultSubjectMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :default_subject_maps do |t|
      t.string :name, null: false
      t.references :subject, foreign_key: true

      t.timestamps
    end
  end
end
