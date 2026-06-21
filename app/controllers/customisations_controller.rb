# frozen_string_literal: true

class CustomisationsController < ApplicationController
  before_action :authenticate_user!, only: %i[show_available buy equip toggle_mode preview stop_preview]

  def show_available
    authorize current_user, :show? # make it so that it checks if the school is permitted?
    board = Customisation::ShopBoard.call(current_user, preview: current_preview_customisation)
    @shop_categories = board.categories
    @wallet = board.wallet
    @mode = board.mode
  end

  def buy
    authorize current_user, :show?
    @customisation = Customisation.find_by(id: buy_params)
    result = buy_customisation
    clear_preview if result.success?
    flash_notice(result)
    redirect_to show_available_customisations_path
  end

  def equip
    authorize current_user, :show?
    @customisation = Customisation.find_by(id: buy_params)
    result = Customisation::EquipCustomisation.call(current_user, @customisation)
    clear_preview if result.success?
    equip_notice(result)
    redirect_to show_available_customisations_path
  end

  # Try-before-you-buy: store the chosen item in the session so Theme::Selection renders it live
  # across the app. Only previewable look-slots are accepted. Starting a *new* trial is rate-limited
  # (User::COSMETIC_TRIAL_COOLDOWN); switching the item within an already-active trial is free.
  def preview
    authorize current_user, :show?
    customisation = Customisation.find_by(id: buy_params)
    return reject_preview unless customisation&.previewable?
    return reject_cooldown unless trial_active? || current_user.cosmetic_trial_available?

    apply_preview(customisation)
  end

  # End the live preview and fall back to the user's real equipped theme.
  def stop_preview
    authorize current_user, :show?
    clear_preview
    redirect_back_or_to(show_available_customisations_path)
  end

  def toggle_mode
    authorize current_user, :show?
    result = Customisation::SetMode.call(current_user, ActiveModel::Type::Boolean.new.cast(params[:dark]))
    flash[:notice] = result.errors unless result.success?
    redirect_to show_available_customisations_path
  end

  private

  def apply_preview(customisation)
    start_trial unless trial_active?
    session[:preview_customisation_id] = customisation.id
    flash[:notice] = "Previewing #{customisation.name} — buy it to keep it, or stop the preview."
    redirect_back_or_to(show_available_customisations_path)
  end

  def trial_active?
    session[:preview_customisation_id].present?
  end

  def start_trial
    current_user.update!(cosmetic_trial_at: Time.current)
  end

  def reject_preview
    flash[:notice] = "That item can't be previewed."
    redirect_back_or_to(show_available_customisations_path)
  end

  def reject_cooldown
    flash[:notice] = "You've used your free try-out — you can try another look in #{cosmetic_trial_retry_in}."
    redirect_back_or_to(show_available_customisations_path)
  end

  def clear_preview
    session.delete(:preview_customisation_id)
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
end
