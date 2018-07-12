class EntrollmentController < ApplicationController
  def show
    @subjects = current_user.subjects
  end
end
