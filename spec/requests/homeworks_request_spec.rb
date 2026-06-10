# frozen_string_literal: true

require "rails_helper"

RSpec.describe "homeworks controller", :default_creates do
  before { sign_in teacher }

  describe "GET /homeworks/new" do
    context "when no classroom is specified" do
      it "redirects to the dashboard" do
        get new_homework_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "GET /homeworks/:id" do
    let!(:enrollments) { create_list(:enrollment, 10, classroom: classroom) }
    let(:homework) { create(:homework, classroom: classroom) }

    it "renders one row per enrolled student" do
      get homework_path(homework)
      expect(Capybara.string(response.body)).to have_css("tr.student-row", count: 10)
    end

    context "when a student has completed the homework" do
      before do
        homework.homework_progresses.first.update!(completed: true)
        get homework_path(homework)
      end

      it "reports the class completion percentage" do
        expect(Capybara.string(response.body)).to have_css("h3", text: "1 / 10 - 10%")
      end
    end

    context "when a student has partial progress" do
      before do
        homework.homework_progresses.first.update!(progress: 50)
        get homework_path(homework)
      end

      it "shows the student's progress percentage" do
        expect(Capybara.string(response.body)).to have_css("tr.student-row td", text: "50%")
      end
    end

    context "with a lesson homework" do
      let(:lesson) { create(:lesson, topic: topic) }
      let(:homework) { create(:homework, classroom: classroom, topic: topic, lesson: lesson) }

      it "shows the lesson and topic the homework was set for" do
        get homework_path(homework)
        expect(response.body).to include(lesson.title).and include(topic.name)
      end
    end
  end

  describe "DELETE /homeworks/:id" do
    let!(:homework) { create(:homework, classroom: classroom) }

    it "destroys the homework and redirects to the classroom" do
      expect { delete homework_path(homework) }
        .to change { Homework.count }.by(-1)
      expect(response).to redirect_to(classroom_path(classroom))
    end
  end
end
