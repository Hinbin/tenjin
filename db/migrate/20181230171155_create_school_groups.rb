class CreateSchoolGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :school_groups do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
