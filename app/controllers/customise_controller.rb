class CustomiseController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user # make it so that it checks if the school is permitted?
    @subjects = current_user.subjects
    @css_flavour = current_user.dashboard_style
  end
end
