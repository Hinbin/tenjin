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

  # Anti-cheat #4: the teacher anomaly column surfaces students whose recent answers were flagged as
  # answered-too-fast (the signature of an auto-answering extension).
  describe 'the fast-flag anomaly column' do
    before { create(:enrollment, school: school, classroom: classroom, user: student) }

    it 'shows a student\'s recent fast-flag count' do
      quiz = create(:quiz, user: student)
      create_list(:asked_question, 2, quiz: quiz, user: student, flagged_fast: true)

      get classroom_path(classroom)
      expect(Capybara.string(response.body)).to have_css('td.fast-flag-cell span.fast-flag-count', text: '2')
    end

    it 'leaves the cell empty for a student with no flags' do
      get classroom_path(classroom)
      expect(Capybara.string(response.body)).to have_no_css('td.fast-flag-cell span.fast-flag-count')
    end
  end
end
