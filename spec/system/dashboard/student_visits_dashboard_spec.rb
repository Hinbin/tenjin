# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student visits the dashboard", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  it "shows the arrow for a tutorial"

  describe "challenges" do
    let!(:challenge_one) { create(:challenge, topic: topic, end_date: 1.hour.from_now) }
    let!(:answer) { create(:answer, question: question, correct: true) }
    let(:challenge_css_selector) { "#challenge-table tr[data-topic='#{topic.id}']" }

    context "when the student has no challenge progress" do
      before { visit(dashboard_path) }

      it "shows enrolled challenges" do
        expect(page).to have_content(challenge_one.stringify)
      end

      it "navigates to the correct quiz when clicked" do
        find(challenge_css_selector).click
        expect(page).to have_css("p", exact_text: challenge_one.topic.name)
      end

      it "allows answering a challenge question" do # turbolinks bug
        find(challenge_css_selector).click
        find(".question-button", match: :first).click
        expect(page).to have_text("Next Question")
      end

      it "does not show a tick icon"
    end

    context "when the student has progressed a challenge" do
      let!(:progressed_challenge) do
        create(:challenge_progress, user: student, challenge: challenge_one, progress: 70)
      end
      before { visit(dashboard_path) }

      it "shows progress percentage" do
        expect(page).to have_css("td", exact_text: progressed_challenge.progress)
      end
    end

    context "when the student has completed a challenge" do
      let!(:completed_challenge) do
        create(:challenge_progress, user: student, challenge: challenge_one, progress: 100, completed: true)
      end
      before { visit(dashboard_path) }

      it "shows a tick icon" do
        expect(page).to have_css("td i.fa-check")
      end
    end

    context "when there is a challenge for a non-enrolled subject" do
      let(:second_subject) { create(:subject) }
      let!(:second_topic) { create(:topic, subject: second_subject) }
      let!(:non_enrolled_challenge) { Challenge.create_challenge(second_subject) }
      before { visit(dashboard_path) }

      it "does not show the challenge" do
        expect(page).to have_no_content(non_enrolled_challenge.stringify)
      end
    end

    context "when the student has challenge points" do
      let(:student) { create(:student, school: school, challenge_points: 25) }
      before { visit(dashboard_path) }

      it "shows challenge points in the nav bar" do
        expect(page).to have_css("p", exact_text: 25)
      end
    end

    context "when the student has no challenge points" do
      before { visit(dashboard_path) }

      it "does not show challenge points"
    end
  end

  describe "homeworks" do
    let!(:homework) { create(:homework, classroom: classroom, topic: topic) }

    context "with an active homework" do
      before { visit(dashboard_path) }

      it "shows homework assignments" do
        expect(page).to have_content(homework.topic.name).and have_content(homework.required)
      end

      it "shows a times icon" do
        expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > i.fa-times")
      end

      it "does not show an exclamation icon"
    end

    context "when there are 15 outstanding homeworks" do
      before do
        create_list(:homework_progress, 14, user: student, completed: false)
        visit(dashboard_path)
      end

      it "limits the list to 15" do
        expect(page).to have_css("tr.homework-row", count: 15)
      end
    end

    context "when homework is completed" do
      before do
        homework.homework_progresses.find_by!(user: student).update!(completed: true)
        visit(dashboard_path)
      end

      it "shows a tick icon" do
        expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > i.fa-check")
      end
    end

    context "when homework is overdue" do
      let!(:homework) { create(:homework, :overdue, classroom: classroom, topic: topic) }
      before { visit(dashboard_path) }

      it "shows an exclamation icon" do
        expect(page).to have_css(".homework-row[data-homework='#{homework.id}'] > td:last-child > i.fa-exclamation")
      end
    end

    context "when homework was completed more than a week ago" do
      let!(:homework) { create(:homework, :overdue, classroom: classroom, topic: topic, due_date: 2.weeks.ago) }

      before do
        homework.homework_progresses.find_by!(user: student).update!(completed: true)
        visit(dashboard_path)
      end

      it "does not show the homework" do
        expect(page).to have_no_css(".homework-row[data-homework='#{homework.id}']")
      end
    end

    context "when there are multiple homeworks" do
      let!(:homework_future) { create(:homework, due_date: 8.days.from_now, classroom: classroom) }
      before { visit(dashboard_path) }

      it "shows homework in date order" do
        expect(page).to have_css(".homework-row:first-child[data-homework='#{homework.id}']")
          .and have_css(".homework-row:nth-child(2)[data-homework='#{homework_future.id}']")
      end
    end

    context "when the homework has questions" do
      let!(:answer) { create(:answer, question: question, correct: true) }
      before { visit(dashboard_path) }

      it "opens the quiz on click" do
        find(".homework-row").click
        expect(page).to have_css("p", exact_text: homework.topic.name)
      end
    end

    context "when homework is lesson-based" do
      let(:lesson) { create(:lesson, subject: classroom.subject) }
      let!(:homework_lesson) { create(:homework, due_date: 8.days.from_now, classroom: classroom, lesson: lesson) }
      before { visit(dashboard_path) }

      it "shows the lesson title" do
        expect(page).to have_content(homework_lesson.lesson.title)
      end

      context "with lesson questions" do
        before do
          create_list(:question, 10, lesson: homework_lesson.lesson, topic: homework_lesson.lesson.topic)
          visit(dashboard_path)
        end

        it "navigates to a lesson quiz when clicked" do
          find(".homework-row", text: homework_lesson.lesson.title).click
          expect(page).to have_css("p", exact_text: homework_lesson.lesson.title)
        end
      end

      it "stops points being added on third lesson attempt"
      it "prevents you taking a lesson homework that has already been completed"
    end

    context "when homeworks exist for another teacher" do
      before do
        create(:homework)
        visit(dashboard_path)
      end

      it "only shows homeworks for the current teacher" do
        expect(page).to have_css("tr.homework-row", count: 1)
      end
    end
  end
end
