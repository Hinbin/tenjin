# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User visits a classroom", :default_creates, :js do
  let(:classroom) { create(:classroom, subject: quiz_subject, school: teacher.school) }

  before do
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
  end

  context "when looking at the classroom information" do
    before { visit(classroom_path(classroom)) }

    it "shows the name of the classroom" do
      expect(page).to have_content(classroom.name)
    end

    it "shows the name of the students" do
      expect(page).to have_content(student.forename)
    end

    it "navigates to the new homework form" do
      click_link("Set Homework")
      expect(page).to have_current_path(new_homework_path(classroom: {classroom_id: classroom.id}))
    end

    context "when a homework has been created" do
      let!(:homework) { create(:homework, classroom: classroom) }
      before { visit(classroom_path(classroom)) }

      it "navigates to a homework when clicked" do
        find("tr[data-controller='homeworks'][data-id='#{homework.id}']").click
        expect(page).to have_current_path(homework_path(homework))
      end
    end

    context "with homework completion data" do
      let!(:homework) { create(:homework, classroom: classroom) }

      before do
        create_list(:homework_progress, 3, homework: homework, completed: false)
        create_list(:homework_progress, 6, homework: homework, completed: true)
        visit(classroom_path(classroom))
      end

      it "shows the correct percentage of homeworks completed" do
        expect(page).to have_css("td", text: "60%")
      end
    end

    context "when looking at the student table" do
      let(:different_classroom) { create(:classroom, school: school) }

      it "only loads the data table once after going back in the browser" do
        click_link("Set Homework")
        page.go_back
        expect { page.accept_alert }.to raise_error(Capybara::ModalNotFound)
      end

      it "hides reset password buttons by default" do
        expect(page).to have_no_link("Reset Password")
      end

      it "has a working reset password toggle" do
        find_by_id("resetPasswordCheck").set(true)
        within "#students-table" do
          expect(page).to have_link("Reset Password")
        end
      end

      it "resets a student password" do
        find_by_id("resetPasswordCheck").set(true)
        click_link("Reset Password")
        expect(page).to have_no_link("Reset Password").and have_css(".new-password")
      end

      context "with many students and homeworks" do
        before do
          create_list(:enrollment, 10, classroom: classroom)
          create_list(:homework, 10, classroom: classroom)
          visit(classroom_path(classroom))
        end

        it "shows the last 5 homeworks" do
          expect(page).to have_css("tr[data-id='#{student.id}'] svg.fa-times", count: 5)
        end
      end

      context "with many enrolled students" do
        before do
          create_list(:enrollment, 32, classroom: classroom)
          visit(classroom_path(classroom))
        end

        it "allows searching students" do
          find("#students-table_filter input").set("#{student.forename} #{student.surname}")
          expect(page).to have_css(".student-data", count: 1)
        end
      end

      context "when a homework is completed" do
        let!(:homeworks) { create_list(:homework, 5, classroom: classroom) }
        let(:completed_homework_progress) { HomeworkProgress.joins(:homework).order("homeworks.due_date desc").second }

        before do
          completed_homework_progress.update!(completed: true)
          visit(classroom_path(classroom))
        end

        it "shows the completed homework in the correct place" do
          expect(page).to have_css("tr[data-id='#{student.id}'] td:nth-child(5) svg:nth-child(2).fa-check")
        end
      end

      context "when a homework exists for a different classroom" do
        let!(:different_homework) { create(:homework, classroom: different_classroom) }
        before { visit(classroom_path(classroom)) }

        it "does not show homeworks for another classroom" do
          expect(page).to have_no_css("svg.fa-times")
        end
      end

      context "with many homeworks" do
        before do
          create_list(:homework, 20, classroom: classroom)
          visit(classroom_path(classroom))
        end

        it "shows 5 homeworks per page" do
          expect(page).to have_css(".homework-data", count: 5)
        end
      end
    end
  end

  describe "as a student" do
    before do
      sign_in student
      visit(classroom_path(classroom))
    end

    it "redirects to root" do
      expect(page).to have_current_path(root_path)
    end
  end

  context "when navigating from classroom to homework form and back" do
    before do
      visit(classroom_path(classroom))
      click_link("Set Homework")
      find("section#set_homework")
      page.go_back
    end

    it "shows the search box only once" do
      expect(page).to have_css('input[type="search"]', count: 1)
    end
  end
end
