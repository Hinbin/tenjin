# frozen_string_literal: true

class CreateAppErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :app_errors do |t|
      t.string :exception_class, null: false
      t.text :message
      t.text :backtrace
      t.string :request_id
      t.string :controller
      t.string :action
      t.string :url
      t.jsonb :params, default: {}, null: false
      t.bigint :user_id
      t.bigint :admin_id
      t.string :job_class
      t.string :job_id
      t.string :environment, null: false
      t.jsonb :context, default: {}, null: false

      t.timestamps
    end

    add_index :app_errors, :created_at
    add_index :app_errors, :exception_class
    add_index :app_errors, :request_id
  end
end
