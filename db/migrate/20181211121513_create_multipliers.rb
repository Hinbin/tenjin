class CreateMultipliers < ActiveRecord::Migration[5.2]
  def change
    create_table :multipliers do |t|
      t.integer :score
      t.integer :multiplier

      t.timestamps
    end
  end
end
