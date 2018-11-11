class CreatePermittedSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :permitted_schools do |t|

      t.text :school_id
      t.text :name
      t.text :token

      t.timestamps
    end
  end
end