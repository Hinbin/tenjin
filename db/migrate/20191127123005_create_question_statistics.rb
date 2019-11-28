class CreateQuestionStatistics < ActiveRecord::Migration[6.0]
  def change
    create_table :question_statistics do |t|
      t.integer :number_asked
      t.integer :number_correct
      t.references :question, null: false, foreign_key: true, index: {unique: true}
      
      t.timestamps
    end
  end
end
