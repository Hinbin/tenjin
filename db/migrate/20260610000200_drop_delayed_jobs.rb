# frozen_string_literal: true

# DEPLOY NOTE: run only after confirming no pending jobs in the delayed_jobs table
# in production (check with: SELECT COUNT(*) FROM delayed_jobs WHERE failed_at IS NULL;)
class DropDelayedJobs < ActiveRecord::Migration[8.0]
  def up
    drop_table :delayed_jobs
  end

  def down
    create_table :delayed_jobs do |t|
      t.integer :priority, default: 0, null: false
      t.integer :attempts, default: 0, null: false
      t.text :handler, null: false
      t.text :last_error
      t.datetime :run_at
      t.datetime :locked_at
      t.datetime :failed_at
      t.string :locked_by
      t.string :queue
      t.timestamps null: false
    end
    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
  end
end
