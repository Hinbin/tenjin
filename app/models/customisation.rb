# frozen_string_literal: true

class Customisation < ApplicationRecord
  validates :cost, presence: true
  validates :name, presence: true
  validates :value, presence: true
  validates :image, presence: true, if: :is_dashboard_style
  enum :customisation_type, { dashboard_style: 0, leaderboard_icon: 1, subject_image: 2 }

  has_many :customisation_unlocks
  has_many :active_customisations

  has_one_attached :image

  before_save :make_unpurchasable_if_retired

  def is_dashboard_style
    customisation_type == 'dashboard_style'
  end

  def make_unpurchasable_if_retired
    return unless retired?

    self.purchasable = false
    self.sticky = false
  end
end
