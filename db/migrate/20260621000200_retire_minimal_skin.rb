# frozen_string_literal: true

# The "Minimal" skin was dropped from the design (replaced by Matchday/Manga/Street). Remove its
# catalog rows (skin + palettes) and any equip/unlock rows that reference them. Students left with
# no equipped skin/palette render the default (arcade) via Theme::Selection's fallback, and the
# next Customisation::SeedCosmetics run backfills a real arcade equip for them.
#
# Raw SQL (enum ints: skin=3, palette=4) keeps this independent of future model/enum changes.
class RetireMinimalSkin < ActiveRecord::Migration[8.0]
  MINIMAL_SELECT = <<~SQL.squish
    SELECT id FROM customisations
    WHERE (customisation_type = 3 AND value = 'minimal')
       OR (customisation_type = 4 AND value LIKE 'minimal:%')
  SQL

  def up
    execute "DELETE FROM active_customisations WHERE customisation_id IN (#{MINIMAL_SELECT})"
    execute "DELETE FROM customisation_unlocks  WHERE customisation_id IN (#{MINIMAL_SELECT})"
    execute "DELETE FROM customisations WHERE id IN (#{MINIMAL_SELECT})"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Minimal skin was retired; re-seed from the catalog to restore.'
  end
end
