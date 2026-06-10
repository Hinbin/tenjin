# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Employee views a user record", :default_creates, :js do
  let!(:student_enrollment) { create(:enrollment, user: student, classroom: classroom) }
  let!(:teacher_enrollment) { create(:enrollment, user: teacher, classroom: classroom) }
  let!(:homework) { create(:homework, classroom: classroom, topic: topic) }

  before do
    sign_in teacher
    visit(user_path(student))
  end

  describe "homework status" do
    it "shows a cross icon next to uncompleted homework" do
      expect(page).to have_content(homework.topic.name).and have_css("i.fa-times")
    end

    context "when homework is completed" do
      before do
        homework.homework_progresses.find_by!(user: student).update!(completed: true)
        visit(user_path(student))
      end

      it "shows a check icon" do
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

      it "hides homework from classrooms the teacher does not belong to" do
        expect(page).to have_no_css("tr[data-homework='#{homework_different_class.id}']")
      end
    end
  end

  describe "password reset" do
    let(:new_password) { FFaker::Internet.password }

    it "resets a student password" do
      update_password(new_password)
      sign_out teacher
      log_in_through_front_page(student.username, new_password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end
end
