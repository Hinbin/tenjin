class CreatePermittedSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :permitted_schools do |t|

      t.text :schoolID
      t.text :name
      t.text :token

      t.timestamps
    end
  end
end