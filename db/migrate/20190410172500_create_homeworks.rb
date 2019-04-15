class CreateHomeworks < ActiveRecord::Migration[6.0]
  def change
    create_table :homeworks do |t|
      t.references :classroom, foreign_key: true
      t.references :topic, foreign_key: true
      t.datetime :due_date
      t.integer :required

      t.timestamps
    end
  end
end
