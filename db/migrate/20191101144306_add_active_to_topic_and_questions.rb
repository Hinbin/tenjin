class AddActiveToTopicAndQuestions < ActiveRecord::Migration[6.0]
  def change
    add_column :topics, :active, :boolean, default: true
    add_column :questions, :active, :boolean, default: true
  end
end
