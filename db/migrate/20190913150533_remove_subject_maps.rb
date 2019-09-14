class RemoveSubjectMaps < ActiveRecord::Migration[6.0]
  def change
    drop_table :default_subject_maps
    drop_table :subject_maps     
  end
end
