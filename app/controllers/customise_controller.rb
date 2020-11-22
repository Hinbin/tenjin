# frozen_string_literal: true

class CustomiseController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects
    @dashboard_style = find_dashboard_style
    @bought_customisations = CustomisationUnlock.where(user: current_user).pluck(:customisation_id)
    @purchased_styles = Customisation.with_attached_image.where(id: @bought_customisations)
    @available_styles = Customisation.with_attached_image.where(purchasable: true)
                                     .where.not(id: @bought_customisations)
  end

  def update
    authorize current_user, :show?
    @customisation = Customisation.find_by(id: customisation_params[:id])
    result = buy_customisation
    flash_notice(result)
    redirect_to dashboard_path
  end

  private

  def buy_customisation
    Customisation::BuyCustomisation.call(current_user, @customisation)
  end

  def flash_notice(result)
    flash[:notice] = result.errors unless result.success?
    flash[:notice] = "Congratulations!  You have bought #{@customisation.name}" if result.success?
  end

  def customisation_params
    params.require(:customisation).permit(:id)
  end

  def purchase_failed(exception)
    flash[:notice] = exception.message
    redirect_to dashboard_path
  end
end
