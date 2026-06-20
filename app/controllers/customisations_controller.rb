# frozen_string_literal: true

class CustomisationsController < ApplicationController
  before_action :authenticate_user!, only: %i[show_available buy equip toggle_mode]

  def show_available
    authorize current_user, :show? # make it so that it checks if the school is permitted?
    board = Customisation::ShopBoard.call(current_user)
    @shop_categories = board.categories
    @wallet = board.wallet
    @mode = board.mode
  end

  def buy
    authorize current_user, :show?
    @customisation = Customisation.find_by(id: buy_params)
    result = buy_customisation
    flash_notice(result)
    redirect_to show_available_customisations_path
  end

  def equip
    authorize current_user, :show?
    @customisation = Customisation.find_by(id: buy_params)
    result = Customisation::EquipCustomisation.call(current_user, @customisation)
    equip_notice(result)
    redirect_to show_available_customisations_path
  end

  def toggle_mode
    authorize current_user, :show?
    result = Customisation::SetMode.call(current_user, ActiveModel::Type::Boolean.new.cast(params[:dark]))
    flash[:notice] = result.errors unless result.success?
    redirect_to show_available_customisations_path
  end

  private

  def buy_customisation
    Customisation::BuyCustomisation.call(current_user, @customisation)
  end

  def flash_notice(result)
    flash[:notice] = result.errors unless result.success?
    flash[:notice] = "Congratulations!  You have bought #{@customisation.name}" if result.success?
  end

  def equip_notice(result)
    flash[:notice] = result.success? ? "Equipped #{@customisation.name}" : result.errors
  end

  def buy_params
    params.require(:id)
  end
end
