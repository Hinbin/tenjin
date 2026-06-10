# frozen_string_literal: true

require "rails_helper"

RSpec.describe "using a quiz" do
  let!(:student) { create(:student, school: school) }
  let(:question) { create(:question, topic: topic) }
  let(:quiz_subject) { create(:subject) }
  let(:school) { create(:school) }
  let(:topic) { create(:topic, subject: quiz_subject) }
  before do
    sign_in student
  end

  context "when navigating to the root quiz path" do
    let!(:quiz) { create(:quiz, user: student) }

    it "redirects to the latest active quiz" do
      get quizzes_path
      expect(response).to redirect_to(quiz)
    end

    context "when I have multiple quizzes" do
      let!(:quiz) { create(:quiz, user: student, created_at: 1.hour.ago) }
      let!(:new_quiz) { create(:quiz, user: student) }

      it "redirects to the most recently created quiz" do
        get quizzes_path
        expect(response).to redirect_to(new_quiz)
      end
    end
  end

  context "when setting up a quiz" do
    it "redirects to dashboard" do
      get new_quiz_path
      expect(response).to redirect_to dashboard_path
    end

    context "when the subject is valid" do
      let!(:enrollment) { create(:enrollment, school: school, user: student) }

      it "renders the topic select page" do
        get new_quiz_path, params: {subject: enrollment.classroom.subject.name}
        expect(response).to have_http_status(:success)
      end
    end

    context "when the subject is not enrolled by the student" do
      let!(:enrollment) { create(:enrollment, school: school, user: student) }
      let!(:different_subject) { create(:classroom, school: school) }

      it "redirects to dashboard" do
        get new_quiz_path, params: {subject: different_subject.subject.name}
        expect(response).to redirect_to dashboard_path
      end
    end
  end

  context "when selecting a subject that does not exist" do
    subject { get new_quiz_path, params: {subject: "NOSUBJECT"} }

    it { is_expected.to redirect_to(dashboard_path) }

    it "responds with a flash alert" do
      subject
      expect(flash[:alert]).to match(/does not exist/)
    end
  end

  context "when trying to access a quiz" do
    context "when the quiz belongs to another user" do
      let!(:diff_user) { create(:student) }
      let!(:quiz) { create(:new_quiz, user: diff_user, question_order: [question.id]) }

      it "redirects with an alert" do
        get quiz_path(id: quiz.id)
        expect(flash[:alert]).to match(/Quiz does not belong to you/)
      end
    end

    context "when the quiz is finished" do
      let!(:quiz) { create(:new_quiz, user: student, active: false, question_order: [question.id]) }

      it "redirects with a notice" do
        get quiz_path(id: quiz.id)
        expect(flash[:notice]).to match(/Finished!  You got 0%/)
      end
    end
  end

  context "when displaying a question" do
    let!(:multiplier) { create(:multiplier) }
    let(:quiz) { create(:new_quiz, user: student, question_order: [question.id]) }
    let(:classroom) { create(:classroom, subject: quiz_subject) }

    context "when creating a new quiz" do
      let!(:enrollment) { create(:enrollment, school: school, classroom: classroom, user: student) }
      let!(:extra_question) { create(:question, topic: topic) }

      it "creates and redirects to the new quiz" do
        post quizzes_path params: {quiz: {topic_id: topic, subject: quiz_subject}}
        follow_redirect!
        expect(response).to have_http_status(:success)
      end
    end

    it "renders the multiple choice question" do
      get quiz_path(id: quiz.id)
      expect(response).to have_http_status(:success)
    end

    context "when the question is a short answer" do
      let(:short_answer_question) { create(:short_answer_question) }
      let(:quiz) { create(:new_quiz, user: student, question_order: [short_answer_question.id]) }

      it "renders the short answer question" do
        get quiz_path(id: quiz.id)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
