# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super manages subjects", :default_creates, :js do
  let!(:quiz_subject) { create(:subject) }

  before do
    sign_in super_admin
  end

  context "when viewing all subjects" do
    it "lists subjects" do
      visit(subjects_path)
      expect(page).to have_content(quiz_subject.name)
    end

    context "with questions in the subject" do
      let!(:ten_questions_for_subject) { create_list(:question, 10, topic: topic) }

      before { visit(subjects_path) }

      it "shows question count" do
        expect(page).to have_content("10")
      end
    end

    context "with asked questions this week" do
      let!(:five_asked_questions_this_week) { create_list(:asked_question, 5, question: question) }

      before { visit(subjects_path) }

      it "shows this week's asked question count" do
        expect(page).to have_content("5")
      end

      context "with previous week statistics" do
        let!(:seven_asked_questions_previously) { create(:question_statistic, question: question, number_asked: 7) }

        before { visit(subjects_path) }

        it "totals current and previous asked questions" do
          expect(page).to have_css("tr#subject-#{quiz_subject.id} td.asked_questions", text: "12")
        end

        it "counts only this week's asked questions separately" do
          expect(page).to have_css("tr#subject-#{quiz_subject.id} td.asked_questions_this_week", text: "5")
        end
      end
    end

    context "with previous week statistics only" do
      let!(:seven_asked_questions_previously) { create(:question_statistic, question: question, number_asked: 7) }

      before { visit(subjects_path) }

      it "shows overall asked question count" do
        expect(page).to have_content("7")
      end
    end

    context "when creating a subject" do
      let(:new_subject_name) { FFaker::Lorem.word }

      before { visit(subjects_path) }

      it "creates and displays the new subject" do
        click_link("Add Subject")
        fill_in("subject[name]", with: new_subject_name)
        click_button("Create Subject")
        expect(page).to have_content(new_subject_name)
      end
    end
  end

  context "when managing an individual subject" do
    def deactivate_subject
      visit(subject_path(quiz_subject))
      click_link("Deactivate Subject")
      page.accept_alert
      find("table#active-subjects")
    end

    it "shows the subject heading when navigating to the subject" do
      visit(subjects_path)
      click_link(quiz_subject.name)
      expect(page).to have_css(".display-4", text: quiz_subject.name)
    end

    context "when editing the subject name" do
      let(:new_subject_name) { FFaker::Lorem.word }

      before { visit(subject_path(quiz_subject)) }

      it "updates the displayed name" do
        fill_in("subject[name]", with: new_subject_name)
        click_button("Update")
        expect(page).to have_css("#subject_name", text: new_subject_name)
      end
    end

    it "moves subject to deactivated list" do
      deactivate_subject
      expect(page).to have_css("#deactivated-subjects tr td", text: quiz_subject.name)
    end

    context "when deactivating a subject with enrolled students" do
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: student, subject: quiz_subject) }

      it "hides subject from student dashboard" do
        deactivate_subject
        sign_out super_admin
        sign_in student
        visit(dashboard_path)
        expect(page).to have_no_content(quiz_subject.name)
      end

      it "hides subject from classroom list" do
        deactivate_subject
        sign_out super_admin
        sign_in school_admin
        visit(classrooms_path)
        expect(page).to have_no_content(quiz_subject.name)
      end
    end
  end
end
