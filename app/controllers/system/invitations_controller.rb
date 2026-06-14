# frozen_string_literal: true

module System
  class InvitationsController < Devise::InvitationsController
    before_action :authenticate_admin!

    def new
      authorize current_admin, policy_class: System::AdminPolicy
      super
    end

    private

    def invite_resource
      super { |admin| admin.role = "school_group" }
    end

    def after_accept_path_for(_resource)
      system_subjects_path
    end

    def pundit_user
      current_admin
    end
  end
end
