# frozen_string_literal: true

class AddMotionPrefToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :motion_pref, :boolean, default: true, null: false
  end
end
