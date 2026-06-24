# frozen_string_literal: true

# Generates a stable, anonymous "Plant + Mythical figure" display name (e.g. "Nettle Pegasus")
# for use on cross-school leaderboards, where a student's real name must never be shown to viewers
# from a different school. Deterministic: the same seed always yields the same pseudonym, so a
# backfill/regeneration produces identical results and the name never flickers between requests.
module Leaderboard::Pseudonym
  PLANTS = %w[
    Nettle Bramble Thistle Fennel Clover Bracken Foxglove Hawthorn Ivy Sorrel
    Marigold Heather Juniper Willow Aster Cedar Larkspur Mallow Nightshade Yarrow
    Dahlia Cowslip Burdock Comfrey Teasel Tansy Vetch Rowan Sage
    Borage Chicory Dandelion Elder Gorse Holly Lavender Mistletoe Primrose Reed
  ].freeze

  MYTHICAL = %w[
    Pegasus Sphinx Griffin Phoenix Chimera Hydra Kraken Basilisk Wyvern Minotaur
    Cyclops Centaur Banshee Selkie Kelpie Gorgon Cerberus Manticore Roc Valkyrie
    Naiad Dryad Faun Golem Djinn Leviathan Unicorn Salamander Thunderbird Yeti
    Cockatrice Harpy Nymph Oracle Satyr Siren Triton Wendigo Fenrir Pixie
  ].freeze

  module_function

  # seed: any Integer (callers pass Zlib.crc32 of a stable per-user value).
  def generate(seed)
    rng = Random.new(seed)
    "#{PLANTS[rng.rand(PLANTS.length)]} #{MYTHICAL[rng.rand(MYTHICAL.length)]}"
  end
end
