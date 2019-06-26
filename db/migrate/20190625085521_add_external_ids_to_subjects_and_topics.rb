class AddExternalIdsToSubjectsAndTopics < ActiveRecord::Migration[6.0]
  def change
    add_column :subjects, :external_id, :integer
    add_column :topics, :external_id, :integer
  end
end
