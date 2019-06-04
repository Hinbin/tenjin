class AddExternalIdsToQuestionAndAnswers < ActiveRecord::Migration[6.0]
  def change
    add_column :questions, :external_id, :integer
    add_column :answers, :external_id, :integer
  end
end
