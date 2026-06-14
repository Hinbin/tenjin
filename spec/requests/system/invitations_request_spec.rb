# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Invitations", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /admins/invitation/new" do
    it "renders the invitation form via the System::InvitationsController" do
      get new_admin_invitation_path
      expect(response).to have_http_status(:ok)
      expect(controller.class).to eq(System::InvitationsController)
    end
  end
end
