# frozen_string_literal: true

require "rails_helper"

RSpec.describe "questions controller", :default_creates do
  describe "GET /questions" do
    context "as a student" do
      before { sign_in student }

      it "redirects to the dashboard" do
        get questions_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a question author" do
      let(:author) { create(:question_author, subject: quiz_subject) }

      before { sign_in author }

      it "returns a success response" do
        get questions_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /questions/download_topic" do
    let(:author) { create(:question_author, subject: quiz_subject) }
    let!(:question) { create(:question, topic: topic) }

    before { sign_in author }

    it "responds with the questions as a JSON attachment named after the topic" do
      get download_topic_questions_path(topic_id: topic.id)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.headers["Content-Disposition"])
        .to include("attachment").and include("filename=#{topic.name}.json")
      expect(JSON.parse(response.body).first).to include("question_text", "answers")
    end
  end

  describe "POST /questions/import" do
    let(:author) { create(:question_author, subject: quiz_subject) }

    before { sign_in author }

    context "without an attached file" do
      it "re-renders the import form with an alert" do
        post import_questions_path, params: {topic_id: topic.id}

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Please attach a file")
      end
    end
  end
end
