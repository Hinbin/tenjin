# frozen_string_literal: true

# A stable anonymous leaderboard display name (see Leaderboard::Pseudonym). Assigned on every user
# creation path (Wonde import, OAuth, future self-serve) so a row can never lack one when it appears
# outside its own school.
module Pseudonymable
  extend ActiveSupport::Concern

  included do
    before_validation :assign_pseudonym, on: :create
  end

  # Single source of truth for the leaderboard display-name privacy rule: the real name is only ever
  # shown to a viewer from the same school; everyone else sees the anonymous pseudonym. The SQL in
  # Leaderboard::BuildLeaderboard mirrors this so other schools' real names never enter the result
  # set in the first place.
  def leaderboard_name_for(viewer)
    if viewer.present? && viewer.school_id == school_id
      "#{forename} #{surname[0]}"
    else
      pseudonym
    end
  end

  private

  def assign_pseudonym
    return if pseudonym.present?

    seed = upi.present? ? Zlib.crc32(upi) : Random.rand(2**32)
    self.pseudonym = Leaderboard::Pseudonym.generate(seed)
  end
end
