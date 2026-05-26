# frozen_string_literal: true

require "rails_helper"

RSpec.describe "using question editing" do
  describe "as a student" do
    let(:student) { create(:student) }

    before { sign_in student }

    it "redirects to the dashboard" do
      get questions_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as a question author" do
    let(:quiz_subject) { create(:subject) }
    let(:author) { create(:question_author, subject: quiz_subject) }

    before { sign_in author }

    it "returns a success response" do
      get questions_path
      expect(response).to have_http_status(:success)
    end
  end
end
