class CustomiseController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects
    @css_flavour = find_dashboard_style
    @dashboard_styles = Customisation.where(customisation_type: 'dashboard_style')
    @leaderboard_icons = Customisation.where(customisation_type: 'leaderboard_icon')
    @bought_customisations = CustomisationUnlock.where(user: current_user).pluck(:customisation_id)
  end

  def update
    authorize current_user, :show?
    @customisation = Customisation.where('customisation_type = 0 AND value = ?', customisation_params[:value]).first
    result = Customisation::BuyCustomisation.new(current_user, @customisation).call
    flash_notice(result)

    redirect_to dashboard_path
  end

  def flash_notice(result)
    flash[:notice] = result.errors unless result.success?
    flash[:notice] = 'Congratulations!  You have bought ' + @customisation.name if result.success?
  end

  def customisation_params
    params.require(:customisation).permit(:type, :value)
  end

  def purchase_failed(exception)
    flash[:notice] = exception.message
    redirect_to dashboard_path
  end
end
