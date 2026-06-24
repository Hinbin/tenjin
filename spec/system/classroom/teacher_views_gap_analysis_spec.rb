# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Teacher views gap analysis', :default_creates, :js, type: :system do
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:hard_question) { create(:short_answer_question, topic: topic) }

  before do
    create(:enrollment, classroom: classroom, user: teacher)
    create(:enrollment, classroom: classroom, user: student)
    create(:student_question_statistic, user: student, question: hard_question,
                                        number_asked: 10, number_correct: 2, score_sum: 2.0)
    create(:question_statistic, question: hard_question, number_asked: 1000, number_correct: 800, score_sum: 800.0)
    create(:usage_statistic, user: student, topic: topic, quizzes_started: 4)
    sign_in teacher
  end

  it 'renders the class gap analysis and drills into a student' do
    visit(classroom_path(classroom))
    click_link('View Gap Analysis')

    expect(page).to have_text('Gap analysis')
    expect(page).to have_css('h2.tjs-display', text: /student activity/i)
    expect(page).to have_css('h2.tjs-display', text: /standing vs cohort by topic/i)
    expect(page).to have_css('h2.tjs-display', text: /hardest questions/i)
    expect(page).to have_text(topic.name)
    # Hardest questions now lists the specific question stems, not the question type.
    expect(page).to have_text(hard_question.question_text.to_plain_text)
    # Answered count comes from the durable rollup (number_asked: 10), not the unwritten usage column.
    expect(page).to have_css('.tj-gap-card', text: /questions answered\s*10/i)

    click_link("#{student.forename} #{student.surname}")

    expect(page).to have_text('Personal gap report')
    expect(page).to have_css('h2.tjs-display', text: /by lesson/i)
  end
end
