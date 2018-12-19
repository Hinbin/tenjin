class CreateTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :topics do |t|      
      t.string :name, null:false
      t.references :subject, foreign_key: true

      t.timestamps
    end      
  end
end
