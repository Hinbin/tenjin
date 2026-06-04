# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User creates a quiz", :default_creates, :js do
  describe "picking a subject" do
    let(:subject_cs) { create(:computer_science) }
    let(:classroom_cs) { create(:classroom, subject: subject_cs, school: school) }

    context "with a subject-specific image" do
      before do
        create(:enrollment, classroom: classroom_cs, user: student)
        log_in
      end

      it "shows a subject image" do
        expect(page).to have_css("img[src*=computer-science]")
      end
    end

    context "with no subject-specific image" do
      before do
        setup_subject_database
        log_in
      end

      it "shows a default subject image" do
        expect(page).to have_css("img[src*=default-subject]")
      end

      it "navigates to the topic select page" do
        find(class: "subject-carousel-item-image").click
        expect(page).to have_content(/Select topic/i)
      end
    end
  end

  context "when creating two quizzes in quick succession" do
    before do
      setup_subject_database
      create_list(:answer, 3, question: question)
      sign_in student
      navigate_to_quiz
      visit(dashboard_path)
      navigate_to_quiz
    end

    it "redirects to the dashboard with a wait message" do
      expect(page).to have_current_path(dashboard_path)
        .and have_content("You need to wait")
    end
  end

  context "when creating a quiz for the same topic multiple times" do
    # TopicScore has no visible representation during the quiz itself;
    # it only appears on the leaderboard page. DB assertions are appropriate here.
    let(:user_topic_score) { TopicScore.find_by!(user: student, topic: topic).score }
    let!(:question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      sign_in student
    end

    context "on the first attempt" do
      before { navigate_to_quiz }

      it "awards leaderboard points" do
        find(".question-button").click
        find(".correct-answer")
        expect(user_topic_score).to eq(1)
      end
    end

    context "on the third attempt" do
      let!(:two_quizzes_started) { create(:usage_statistic, user: student, topic: topic, quizzes_started: 2) }

      before { navigate_to_quiz }

      it "awards leaderboard points" do
        find(".question-button").click
        find(".correct-answer")
        expect(user_topic_score).to eq(1)
      end
    end

    context "with a lucky dip quiz" do
      let!(:three_quizzes_started) { create(:usage_statistic, user: student, topic: topic, quizzes_started: 3) }

      before { navigate_to_lucky_dip }

      it "always awards leaderboard points" do
        expect(page).to have_no_content("not counting")
      end
    end

    context "when you should not be allowed to score" do
      let!(:three_quizzes_started) { create(:usage_statistic, user: student, topic: topic, quizzes_started: 3) }

      before { navigate_to_quiz }

      it "informs the user they cannot currently score leaderboard points for this quiz" do
        expect(page).to have_content("not counting")
      end

      context "when a prior score exists" do
        let!(:prior_score) { create(:topic_score, user: student, topic: topic, score: 3) }

        it "does not update the leaderboard score" do
          find(".question-button").click
          find(".correct-answer")
          expect(user_topic_score).to eq(3)
        end
      end
    end
  end

  describe "selecting a topic" do
    let(:topic) { create(:topic, subject: quiz_subject) }

    before do
      setup_subject_database
      create(:question, topic: topic)
      log_in
    end

    context "when viewing the topic select page" do
      before { visit(new_quiz_path(params: {subject: quiz_subject.name})) }

      it "lists available topics" do
        find(:xpath, "//select/option[1]")
        expect(page).to have_select("quiz_topic_id", options: ["Lucky Dip", topic.name])
      end
    end

    it "creates a quiz on the correct topic" do
      navigate_to_quiz
      expect(page).to have_current_path(%r{quizzes/[0-9]*})
    end

    context "with an active dashboard customisation" do
      let!(:active_customisation) do
        create(:active_customisation, user: student, customisation: create(:dashboard_customisation, value: "orange"))
      end

      before { visit(new_quiz_path(params: {subject: quiz_subject.name})) }

      it "has a separator of the correct colour" do
        expect(page).to have_css(".heading-divider[style*='#{active_customisation.customisation.value}']")
      end
    end
  end
end
