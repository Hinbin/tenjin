class CreateUserSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :user_settings do |t|
      t.references :user, foreign_key: true
      t.text :placeholderSetting

      t.timestamps
    end
  end
end
