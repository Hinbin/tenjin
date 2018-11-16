class SettingsController < ApplicationController
  def index
    @settings = policy_scope(UserSetting)
    @settings = UserSetting.create if @settings.blank?
    redirect_to @settings.first
  end

  def show
    @subjects = GetSchoolClasses.new.call
    authorize @settings
  end
end
