# frozen_string_literal: true

class CustomisationsController < ApplicationController
  before_action :authenticate_user!

  def show_available
    authorize current_user, :show? # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects
    @dashboard_style = find_dashboard_style
    @bought_customisations = CustomisationUnlock.where(user: current_user).pluck(:customisation_id)
    @purchased_styles = Customisation.with_attached_image.where(id: @bought_customisations)
    @available_styles = Customisation.with_attached_image.where(purchasable: true)
      .where.not(id: @bought_customisations)
      .order("RANDOM()")
  end

  def buy
    authorize current_user, :show?
    customisation = Customisation.find_by(id: params[:id])
    result = Customisation::BuyCustomisation.call(current_user, customisation)
    flash[:notice] = result_message(customisation, result)
    redirect_to dashboard_path
  end

  private

  def result_message(customisation, result)
    result.success? ? "Congratulations! You have bought #{customisation.name}" : result.errors
  end
end
