# frozen_string_literal: true

class CustomisationsController < ApplicationController
  before_action :authenticate_user!, only: %i[show_available buy]
  before_action :authenticate_admin!, only: %i[index new edit create update]

  def index
    authorize current_admin, policy_class: CustomisationPolicy
    @customisations = policy_scope(Customisation).where(retired: false).with_attached_image
    @retired_customisations = policy_scope(Customisation).where(retired: true).with_attached_image
  end

  def new
    @customisation = authorize Customisation.new(purchasable: false, retired: false)
    render :edit
  end

  def edit
    @customisation = authorize find_customisation
  end

  def create
    @customisation = authorize Customisation.new(customisation_params)

    if @customisation.save
      redirect_to customisations_path, notice: "Created new customisation #{@customisation.name}"
    else
      render :edit
    end
  end

  def update
    customisation = authorize find_customisation
    customisation.update(customisation_params)
    redirect_to customisations_path
  end

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

  def find_customisation
    Customisation.find(params[:id])
  end

  def result_message(customisation, result)
    result.success? ? "Congratulations! You have bought #{customisation.name}" : result.errors
  end

  def customisation_params
    params.require(:customisation).permit(:name, :value, :purchasable, :sticky, :image, :customisation_type, :cost, :retired)
  end
end
