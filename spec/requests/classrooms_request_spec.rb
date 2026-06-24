# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Classrooms', :default_creates, type: :request do
  before do
    sign_in school_admin
    classroom
  end

  it 'shows which classrooms have been retrieved from Wonde' do
    get classrooms_path
    html = Capybara.string(response.body)
    expect(html).to have_text(classroom.name)
  end

  it 'allows visiting the classroom assignment page' do
    get classrooms_path
    html = Capybara.string(response.body)
    expect(html).to have_css('a', text: 'Setup Classrooms')
  end

  # Anti-cheat #4: the teacher anomaly surface flags students whose recent answers were flagged as
  # answered-too-fast (the signature of an auto-answering extension) — a warning banner at the top of
  # the page and an exclamation mark beside the flagged student's name.
  describe 'the fast-flag anomaly surface' do
    before { create(:enrollment, school: school, classroom: classroom, user: student) }

    it 'warns about a flagged student with a banner and a mark beside their name' do
      quiz = create(:quiz, user: student)
      create_list(:asked_question, 2, quiz: quiz, user: student, flagged_fast: true)

      get classroom_path(classroom)
      html = Capybara.string(response.body)
      expect(html).to have_css('.tj-alert-warning', text: 'Possible auto-answering detected')
      expect(html).to have_css('.tj-alert-warning', text: "#{student.forename} #{student.surname}")
      expect(html).to have_css('td i.fast-flag-mark')
    end

    it 'shows no warning for a student with no flags' do
      get classroom_path(classroom)
      html = Capybara.string(response.body)
      expect(html).to have_no_css('.tj-alert-warning')
      expect(html).to have_no_css('td i.fast-flag-mark')
    end
  end
end
