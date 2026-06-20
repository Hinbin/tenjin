# frozen_string_literal: true

class CustomisationsController < ApplicationController
  before_action :authenticate_user!, only: %i[show_available buy equip]
  before_action :authenticate_admin!, only: %i[index show update new destroy]
  before_action :set_customisation, only: %i[edit update delete]

  def index
    authorize current_admin, policy_class: CustomisationPolicy
    @customisations = policy_scope(Customisation).where(retired: false)
    @retired_customisations = policy_scope(Customisation).where(retired: true)
  end

  def new
    @customisation = Customisation.new(purchasable: false, retired: false)
    authorize @customisation
    render :edit
  end

  def edit
    authorize @customisation
  end

  def create
    @customisation = Customisation.new(customisation_params)
    authorize @customisation

    if @customisation.save
      redirect_to customisations_path, notice: "Created new customisation #{@customisation.name}"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def update
    authorize @customisation
    @customisation.update(customisation_params)
    @customisation.save
    redirect_to customisations_path
  end

  def show_available
    authorize current_user, :show? # make it so that it checks if the school is permitted?
    board = Customisation::ShopBoard.call(current_user)
    @shop_categories = board.categories
    @wallet = board.wallet
    load_legacy_styles
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

  private

  # Legacy admin styles + leaderboard icons stay buyable below the Reward Shop (the FontAwesome
  # leaderboard icon is still rendered live on the leaderboard).
  def load_legacy_styles
    @subjects = current_user.subjects
    @dashboard_style = find_dashboard_style
    @bought_customisations = CustomisationUnlock.where(user: current_user).pluck(:customisation_id)
    @purchased_styles = Customisation.where(id: @bought_customisations).with_attached_image
    @available_styles = Customisation.where(purchasable: true)
                                     .where.not(id: @bought_customisations)
                                     .with_attached_image
                                     .order('RANDOM()')
  end

  def set_customisation
    @customisation = Customisation.find(params.expect(:id))
  end

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

  def purchase_failed(exception)
    flash[:notice] = exception.message
    redirect_to dashboard_path
  end

  def customisation_params
    params.expect(customisation: %i[name value purchasable sticky image customisation_type cost
                                    retired])
  end
end
