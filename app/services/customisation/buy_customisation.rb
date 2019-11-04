# frozen_string_literal: true

class Customisation::BuyCustomisation < ApplicationService
  def initialize(user, customisation)
    @user = user
    @customisation = customisation
  end

  def call
    return error_openstruct('Customisation not found') unless @customisation.present?
    return error_openstruct('User not found') unless @user.present?

    unlock = CustomisationUnlock.where(customisation: @customisation, user: @user).first_or_initialize
    if unlock.new_record?
      return error_openstruct('You do not have enough points') unless funds_present?

      unlock.user = @user
      deduct_challenge_points
    end
    destroy_old_active_customisation
    create_new_active_customisation
    unlock.save!
    OpenStruct.new(success?: true, user: @user, errors: nil)
  end

  protected

  def deduct_challenge_points
    @user.challenge_points -= @customisation.cost
    @user.save!
  end

  def funds_present?
    @user.challenge_points >= @customisation.cost
  end

  def destroy_old_active_customisation
    ActiveCustomisation.joins(:customisation)
                       .where(customisations: { customisation_type: @customisation.customisation_type })
                       .where(user: @user)
                       .destroy_all
  end

  def create_new_active_customisation
    ActiveCustomisation.create(user: @user, customisation: @customisation)
  end

  def error_openstruct(error)
    OpenStruct.new(success?: false, user: @user, errors: error)
  end
end
