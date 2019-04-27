class AddOrderToQuizzes < ActiveRecord::Migration[6.0]
  def change
    add_column :quizzes, :question_order, :integer, array: true
  end
end
