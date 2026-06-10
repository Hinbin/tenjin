# frozen_string_literal: true

require "rails_helper"

RSpec.describe "user controller" do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school: school) }
  let!(:student) { create(:student, school: school) }

  def reset_all_link
    patch reset_all_passwords_school_path(student.school)
  end

  context "when not authorized" do
    context "as a teacher" do
      before do
        sign_in teacher
        reset_all_link
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a student" do
      before do
        sign_in student
        reset_all_link
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end

      it "shows an alert flash message" do
        expect(flash[:alert]).to be_present
      end
    end

    it "allows an authorized user to reset all passwords" # pending — counterpart missing
  end

  describe "GET #index authorization" do
    context "as a teacher" do
      before do
        sign_in teacher
        get users_path
      end

      it "is not authorized" do
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("You are not authorized to perform this action.")
      end
    end

    context "as a student" do
      before do
        sign_in student
        get users_path
      end

      it "is not authorized" do
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("You are not authorized to perform this action.")
      end
    end

    context "as a school admin" do
      let(:school_admin) { create(:school_admin, school: school) }

      before do
        sign_in school_admin
        get users_path
      end

      it "renders the user list" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #show authorization" do
    let(:other_employee) { create(:teacher, school: school) }
    let(:school_admin) { create(:school_admin, school: school) }

    context "as a teacher viewing a student" do
      before do
        sign_in teacher
        get user_path(student)
      end

      it "renders the page with the password reset form" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="user_password"')
      end
    end

    context "as a teacher viewing another employee" do
      before do
        sign_in teacher
        get user_path(other_employee)
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a teacher viewing a school admin" do
      before do
        sign_in teacher
        get user_path(school_admin)
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "managing roles" do
    describe "as a super admin" do
      let(:super_admin) { create(:super_admin) }
      before { sign_in super_admin }

      it "does not allow roles to be added to students" do
        patch set_role_user_path(student, user: {role: "school_admin", subject: school})
        expect(response).to redirect_to(root_path)
      end

      it "allows roles to be added to non-students" # pending — counterpart missing
    end

    describe "as a student" do
      before { sign_in student }

      it "requires super admin authentication" do
        patch set_role_user_path(teacher, user: {role: "school_admin", subject: school})
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end
end
