class Customisation::BuyCustomisation
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
    set_old_customisations_to_inactive
    unlock.active = true
    unlock.save!
    OpenStruct.new(success?: true, user: @user, errors: nil)
  end

  def deduct_challenge_points
    @user.challenge_points -= @customisation.cost
    @user.save!
  end

  def funds_present?
    @user.challenge_points >= @customisation.cost
  end

  def set_old_customisations_to_inactive
    CustomisationUnlock.joins(:customisation)
                       .where(customisations: { customisation_type: @customisation.customisation_type })
                       .where(user: @user, active: true)
                       .update_all(active: false)
  end

  def error_openstruct(error)
    OpenStruct.new(success?: false, user: @user, errors: error)
  end
end
