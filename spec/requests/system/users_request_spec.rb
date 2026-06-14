# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Users", :default_creates, type: :request do
  describe "GET /system/users/manage_roles" do
    before { sign_in super_admin }

    it "renders the manage_roles view" do
      get manage_roles_system_users_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /system/users/:id/set_role" do
    context "as a super admin" do
      before { sign_in super_admin }

      it "adds a role" do
        employee = create(:user, school: school, role: :employee)
        expect {
          patch set_role_system_user_path(employee), params: {user: {role: "school_admin"}}
        }.to change { employee.reload.has_role?(:school_admin) }.from(false).to(true)
      end

      it "does not allow roles to be added to students" do
        patch set_role_system_user_path(student), params: {user: {role: "school_admin", subject: school}}
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "requires admin authentication" do
        patch set_role_system_user_path(teacher), params: {user: {role: "school_admin", subject: school}}
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "DELETE /system/users/:id/remove_role" do
    before { sign_in super_admin }

    it "removes a role" do
      employee = create(:user, school: school, role: :employee)
      employee.add_role(:school_admin)
      expect {
        delete remove_role_system_user_path(employee), params: {user: {role: "school_admin"}}
      }.to change { employee.reload.has_role?(:school_admin) }.from(true).to(false)
    end
  end

  describe "PATCH /system/users/:id/update_email" do
    let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html"} }

    before { sign_in super_admin }

    it "updates the email" do
      employee = create(:user, school: school, role: :employee)
      patch update_email_system_user_path(employee), params: {user: {email: "new@example.com"}}, headers: turbo_headers
      expect(employee.reload.email).to eq("new@example.com")
    end
  end
end
