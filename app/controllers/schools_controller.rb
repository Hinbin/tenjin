# frozen_string_literal: true

class SchoolsController < ApplicationController
  before_action :authenticate_user!

  def sync
    school = authorize find_school
    school.update_attribute(:sync_status, "queued")
    SyncSchoolJob.perform_later school
    head :no_content
  end

  def reset_all_passwords
    authorize find_school
    ResetUserPasswordsJob.perform_later(current_user)
    flash[:alert] = "Request received.  You will receive an email shortly with usernames and passwords."
    redirect_to users_path
  end

  private

  def find_school
    School.find(params[:id])
  end
end
