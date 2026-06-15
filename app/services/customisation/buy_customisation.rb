# frozen_string_literal: true

class Customisation::BuyCustomisation < ApplicationCommand
  def initialize(user:, customisation:)
    @user = user
    @customisation = customisation
  end

  def call
    return failure("Customisation not found") if @customisation.blank?
    return failure("User not found") if @user.blank?

    unlock = CustomisationUnlock.where(customisation: @customisation, user: @user).first_or_initialize
    if unlock.new_record?
      return failure("You do not have enough points") unless funds_present?

      unlock.user = @user
    end

    ApplicationRecord.transaction do
      deduct_challenge_points if unlock.new_record?
      destroy_old_active_customisation
      create_new_active_customisation
      unlock.save!
    end

    success
  end

  private

  def deduct_challenge_points
    @user.challenge_points -= @customisation.cost
    @user.save!
  end

  def funds_present?
    @user.challenge_points >= @customisation.cost
  end

  def destroy_old_active_customisation
    ActiveCustomisation.joins(:customisation)
      .where(customisations: {customisation_type: @customisation.customisation_type})
      .where(user: @user)
      .destroy_all
  end

  def create_new_active_customisation
    ActiveCustomisation.create(user: @user, customisation: @customisation)
  end
end
