# frozen_string_literal: true

# Phase 4 follow-up: the legacy customisation slots — dashboard_style (0), leaderboard_icon (1)
# and subject_image (2) — were retired by the skin/avatar uplift. Their enum keys are gone from
# the model, so any surviving rows would raise on load. Purge those rows and their dependents.
class RemoveLegacyCustomisations < ActiveRecord::Migration[8.0]
  LEGACY_TYPES = [0, 1, 2].freeze

  def up
    legacy_ids = select_values(
      "SELECT id FROM customisations WHERE customisation_type IN (#{LEGACY_TYPES.join(',')})"
    )
    return if legacy_ids.empty?

    id_list = legacy_ids.join(',')
    execute "DELETE FROM active_customisations WHERE customisation_id IN (#{id_list})"
    execute "DELETE FROM customisation_unlocks WHERE customisation_id IN (#{id_list})"
    execute "DELETE FROM customisations WHERE id IN (#{id_list})"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
