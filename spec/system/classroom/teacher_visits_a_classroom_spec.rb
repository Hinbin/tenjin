# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teacher visits a classroom", :default_creates, :js do
  before do
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
    visit(classroom_path(classroom))
  end

  describe "the homework completion percentage" do
    let!(:homework) { create(:homework, classroom: classroom) }

    before do
      create_list(:homework_progress, 3, homework: homework, completed: false)
      create_list(:homework_progress, 6, homework: homework, completed: true)
      visit(classroom_path(classroom))
    end

    it "shows the proportion of progresses that are completed" do
      within "#homework-table" do
        expect(page).to have_content("60%")
      end
    end
  end

  describe "the student table" do
    it "resets a student password" do
      click_link("Reset Password")
      expect(page).to have_no_link("Reset Password").and have_css(".new-password")
    end

    context "with many enrolled students" do
      before do
        student.update!(surname: "Zzzqx")
        create_list(:enrollment, 32, classroom: classroom)
        visit(classroom_path(classroom))
      end

      it "allows searching students" do
        within "#students" do
          # Wait for Tabulator to finish rendering before typing.
          # Otherwise, input events can race ahead of `tableBuilt` and the
          # filter call is silently dropped.
          expect(page).to have_css(".tabulator-row.student-data", count: 33)
          find("[data-datatable-target='search']").set(student.surname)
        end
        expect(page).to have_css(".student-data", count: 1)
      end
    end

    context "when a homework is completed" do
      let!(:homeworks) { create_list(:homework, 5, classroom: classroom) }
      let(:second_newest_homework) { homeworks.sort_by(&:due_date).reverse[1] }

      before do
        second_newest_homework.homework_progresses.find_by!(user: student).update!(completed: true)
        visit(classroom_path(classroom))
      end

      it "shows the completed homework in the correct place" do
        within "[data-id='#{student.id}']" do
          expect(page).to have_css("i:nth-child(2).fa-check")
        end
      end
    end

    context "when a homework exists for a different classroom" do
      let(:different_classroom) { create(:classroom, school: school) }
      let!(:different_homework) { create(:homework, classroom: different_classroom) }

      before { visit(classroom_path(classroom)) }

      it "does not show homeworks for another classroom" do
        expect(page).to have_no_css("i.fa-times")
      end
    end

    context "with many homeworks" do
      before do
        create_list(:homework, 20, classroom: classroom)
        visit(classroom_path(classroom))
      end

      it "paginates 5 homeworks per page" do
        expect(page).to have_css(".homework-data", count: 5)
          .and have_css("[data-id='#{student.id}'] i.fa-times", count: 5)
      end
    end
  end

  describe "after navigating away and back" do
    before do
      click_link("Set Homework")
      find("section#set_homework")
      page.go_back
    end

    it "does not duplicate the student data table search box" do
      expect(page).to have_css('input[type="search"]', count: 1)
    end
  end
end
