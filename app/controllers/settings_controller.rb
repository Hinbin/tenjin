class SettingsController < ApplicationController
  def index
    @settings = policy_scope(UserSetting)
    if @settings.blank?
      @settings = UserSetting.create
    end
    redirect_to @settings.first
  end

  def show
    @subjects = GetSchoolClasses.new.call
    authorize @settings
  end

end
