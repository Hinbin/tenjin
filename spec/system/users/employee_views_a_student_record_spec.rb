# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Employee views a user record", :default_creates, :js do
  context "when visiting a user record" do
    before do
      sign_in teacher
      create(:enrollment, user: student, classroom: classroom)
      create(:enrollment, user: teacher, classroom: classroom)
      homework
      visit(user_path(student))
    end

    it "opens the student record webpage" do
      expect(page).to have_current_path(user_path(student))
    end

    it "shows uncompleted homeworks" do
      expect(page).to have_content(homework.topic.name).and have_css("i.fa-times")
    end

    context "when homework is completed" do
      before do
        student.homework_progresses.update_all(completed: true)
        visit(user_path(student))
      end

      it "shows completed homeworks" do
        expect(page).to have_css("i.fa-check")
      end
    end

    context "when the student is enrolled in a second classroom" do
      let(:second_classroom) { create(:classroom, school: school) }
      let!(:homework_different_class) { create(:homework, classroom: second_classroom, topic: topic) }

      before do
        create(:enrollment, user: student, classroom: second_classroom)
        visit(user_path(student))
      end

      it "only shows homeworks for classes the teacher belongs to" do
        expect(page).to have_no_css("tr[data-homework='#{homework_different_class.id}'")
      end
    end

    context "when resetting passwords" do
      let(:different_employee) { create(:teacher, school: school) }

      it "resets a student password" do
        update_password(new_password)
        sign_out teacher
        log_in_through_front_page(student.username, new_password)
        expect(page).to have_content(student.forename).and have_content(student.surname)
      end

      it "does not allow resetting an employee password" do
        visit(user_path(different_employee))
        expect(page).to have_no_css("#user_password")
      end

      it "does not allow resetting a school admin password" do
        visit(user_path(school_admin))
        expect(page).to have_no_css("#user_password")
      end
    end
  end
end
