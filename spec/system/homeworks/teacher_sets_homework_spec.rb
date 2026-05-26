# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teacher sets homework", :default_creates, :js do
  let(:classroom) { create(:classroom, subject: quiz_subject, school: teacher.school) }
  let!(:topic) { create(:topic, subject: quiz_subject) }
  let(:lesson) { create(:lesson, topic: topic) }

  before do
    sign_in teacher
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
  end

  context "when creating a homework" do
    context "after submitting the homework form" do
      before do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        create_homework
        click_button("Set Homework")
      end

      it "shows a success notice" do
        expect(page).to have_css("#flash-notice", text: "homework set")
      end

      it "attaches the homework to the correct classroom" do
        expect(page).to have_content(classroom.name)
      end
    end

    it "redirects when no classroom is specified" do
      visit(new_homework_path)
      expect(page).to have_current_path(dashboard_path)
    end
  end

  context "when viewing a homework" do
    let(:homework) { create(:homework, classroom: classroom) }

    before do
      create_list(:enrollment, 9, classroom: classroom)
      visit(homework_path(homework))
    end

    it "shows all assigned students" do
      expect(page).to have_css("tr.student-row", count: 10)
    end

    it "allows the teacher to delete the homework" do
      click_link("Delete Homework")
      expect(page).to have_current_path(classroom_path(classroom))
    end

    context "when a student has completed the homework" do
      before do
        homework.homework_progresses.find_by!(user: student).update!(completed: true)
        visit(homework_path(homework))
      end

      it "shows the completion percentage" do
        expect(page).to have_content("10%")
      end
    end

    context "when a student has partial progress" do
      before do
        homework.homework_progresses.find_by!(user: student).update!(progress: 50)
        visit(homework_path(homework))
      end

      it "shows progress towards completion" do
        expect(page).to have_content("50%")
      end
    end
  end

  context "when setting a lesson homework" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let(:question_count) { 10 }
    let!(:questions) { create_list(:question, question_count, lesson: lesson, topic: lesson.topic) }

    context "with fewer than 10 questions" do
      let(:question_count) { 9 }

      before do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        select topic.name, from: "Topic"
      end

      it "does not list the lesson" do
        expect(page).to have_no_content(lesson.title)
      end
    end

    it "lists the lesson when there are enough questions"

    context "before a topic has been selected" do
      before { visit(new_homework_path(classroom: {classroom_id: classroom.id})) }

      it "only shows lessons when a topic has been selected" do
        expect(page).to have_no_content(lesson.title)
      end

      it "shows lessons when a topic has been selected"
    end

    context "after submitting the lesson homework form" do
      before do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        create_homework_for_lesson
        click_button("Set Homework")
      end

      it "shows a success notice" do
        expect(page).to have_css("#flash-notice", text: "homework set")
      end
    end

    context "when a topic has been selected" do
      let!(:lesson_different_topic) do
        other_topic = create(:topic, subject: quiz_subject)
        other_lesson = create(:lesson, topic: other_topic)
        create_list(:question, question_count, lesson: other_lesson, topic: other_topic)
        other_lesson
      end

      before do
        visit(new_homework_path(classroom: {classroom_id: classroom.id}))
        select topic.name, from: "Topic"
      end

      it "only shows lessons for the topic selected" do
        expect(page).to have_no_content(lesson_different_topic.title)
      end

      it "shows lessons for the selected topic"
    end
  end

  context "when viewing a homework for a lesson" do
    let!(:questions) { create_list(:question, 10, lesson: lesson, topic: lesson.topic) }

    before do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework_for_lesson
      click_button "Set Homework"
      find_by_id("flash-notice") # homework view page
    end

    it "shows the lesson the homework was created for" do
      expect(page).to have_content(lesson.title)
    end

    it "shows the topic the lesson was created for" do
      expect(page).to have_content(topic.name)
    end
  end
end
