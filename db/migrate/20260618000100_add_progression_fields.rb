# frozen_string_literal: true

# Plan 01, Phase 2 — streak / XP / level progression (phase4-shop-data-model.md §6).
#
# Progression (streak_days, xp, level) is tracked for real and kept SEPARATE from the spendable
# wallet (users.challenge_points). dark_mode holds the Phase 0 theme mode (Theme::Selection reads
# it). On quizzes we record max_streak (best combo, display-only) and progression_recorded_at (an
# idempotency guard so replays/double-submits don't inflate streak/xp).
class AddProgressionFields < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.integer :streak_days, default: 0, null: false
      t.date    :last_streak_day
      t.integer :xp, default: 0, null: false
      t.integer :level, default: 1, null: false
      t.boolean :dark_mode, default: true, null: false
    end

    change_table :quizzes, bulk: true do |t|
      t.integer  :max_streak, default: 0, null: false
      t.datetime :progression_recorded_at
    end
  end
end
