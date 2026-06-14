# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Subjects", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/subjects" do
    it "renders the index" do
      create(:subject, name: "Maths")
      get system_subjects_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Maths")
    end
  end

  describe "POST /system/subjects" do
    it "creates a subject" do
      expect {
        post system_subjects_path, params: {subject: {name: "Biology"}}
      }.to change(Subject, :count).by(1)
    end
  end

  describe "DELETE /system/subjects/:id" do
    it "deactivates the subject" do
      subject_record = create(:subject)
      delete system_subject_path(subject_record)
      expect(subject_record.reload.active).to be(false)
    end
  end
end
