# frozen_string_literal: true

# Phase 4 (reward shop): add the achievement-gating column. Nullable + UNUSED in v1 — every item
# ships points-buyable (decision #4). nil = buyable; a non-nil req marks an item "coming soon /
# locked" display-only until a later pass wires req → real signals. The new customisation_type enum
# slots (skin/palette/avatar/nameplate/name_effect/answer_effect/streak_aura) are appended in the
# model only — customisation_type is already an integer column, so no DB change is needed for them.
class AddReqToCustomisations < ActiveRecord::Migration[8.1]
  def change
    add_column :customisations, :req, :string
  end
end
