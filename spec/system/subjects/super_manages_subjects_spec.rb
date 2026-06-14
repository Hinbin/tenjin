# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super manages subjects", :default_creates, :js do
  before { sign_in super_admin }

  describe "creating a subject" do
    let(:new_subject_name) { FFaker::Lorem.word }

    before { visit(system_subjects_path) }

    it "adds the new subject to the index" do
      click_link("Add Subject")
      fill_in("subject[name]", with: new_subject_name)
      click_button("Create Subject")
      expect(page).to have_content(new_subject_name)
    end
  end

  describe "editing a subject" do
    let(:new_subject_name) { FFaker::Lorem.word }

    before { visit(system_subject_path(quiz_subject)) }

    it "updates the displayed name" do
      fill_in("subject[name]", with: new_subject_name)
      click_button("Update")
      expect(page).to have_css("#subject_name", text: new_subject_name)
    end
  end

  describe "deactivating a subject" do
    def deactivate_subject
      visit(system_subject_path(quiz_subject))
      page.accept_confirm { click_button("Deactivate Subject") }
      find("table#active-subjects")
    end

    it "moves the subject to the deactivated list" do
      deactivate_subject
      expect(page).to have_css("#deactivated-subjects tr td", text: quiz_subject.name)
    end

    context "with a student enrolled in the subject" do
      let!(:enrollment) { create(:enrollment, classroom: classroom, user: student, subject: quiz_subject) }

      it "hides the subject from the student dashboard" do
        deactivate_subject
        sign_out super_admin
        sign_in student
        visit(dashboard_path)
        expect(page).to have_no_content(quiz_subject.name)
      end

      it "hides the subject from the classroom list" do
        deactivate_subject
        sign_out super_admin
        sign_in school_admin
        visit(classrooms_path)
        expect(page).to have_no_content(quiz_subject.name)
      end
    end
  end
end
