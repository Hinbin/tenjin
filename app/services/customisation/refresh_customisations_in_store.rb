# frozen_string_literal: true

class Customisation::RefreshCustomisationsInStore < ApplicationCommand
  def call
    ApplicationRecord.transaction do
      disable_all_customisations
      make_six_purchasable("dashboard_style")
      make_six_purchasable("leaderboard_icon")
    end
    success
  rescue ActiveRecord::ActiveRecordError => e
    failure(e.message)
  end

  private

  def disable_all_customisations
    Customisation.where(purchasable: true).update_all(purchasable: false)
  end

  def make_six_purchasable(customisation_type)
    Customisation.where(customisation_type: customisation_type, retired: false)
      .order(Arel.sql("customisations.sticky DESC, RANDOM()"))
      .limit(6)
      .update_all(purchasable: true)
  end
end
