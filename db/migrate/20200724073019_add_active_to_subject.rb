class AddActiveToSubject < ActiveRecord::Migration[6.0]
  def change
      add_column :subjects, :active, :boolean, default: true, null: false
  end
end
