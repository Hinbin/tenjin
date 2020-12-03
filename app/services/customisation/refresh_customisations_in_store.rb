class Customisation::RefreshCustomisationsInStore < ApplicationService
  def initialize; end

  def call
    disable_all_customisations
    make_six_purchasable('dashboard_style')
    make_six_purchasable('leaderboard_icon')
    OpenStruct.new(success?: true, user: @user, errors: nil)
  end

  def disable_all_customisations
    Customisation.where(purchasable: true).update_all(purchasable: false)
  end

  def make_six_purchasable(customisation_type)
    Customisation.where(customisation_type: customisation_type, retired: false)
                 .order(Arel.sql('customisations.sticky DESC, RANDOM()'))
                 .limit(6)
                 .update_all(purchasable: true)
  end
end
