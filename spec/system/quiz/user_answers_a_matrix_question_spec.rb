# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User answers a matrix question', :default_creates, :js, type: :system do
  let(:question) do
    create(:question, topic:, question_type: 'matrix',
                      config: { 'rows' => [{ 'id' => 'r1', 'label' => 'Python' },
                                           { 'id' => 'r2', 'label' => 'HTML' }],
                                'columns' => [{ 'id' => 'c1', 'label' => 'Interpreted' },
                                              { 'id' => 'c2', 'label' => 'Markup' }],
                                'correct' => { 'r1' => ['c1'], 'r2' => ['c2'] } })
  end

  before do
    setup_subject_database
    question
    sign_in student
    navigate_to_quiz
  end

  it 'renders the grid of rows and columns' do
    expect(page).to have_css('table.tjs-matrix').and have_text('Python').and have_text('Interpreted')
  end

  it 'lets me tick cells, submit, and reveals the result with a Next button' do
    find("input[data-row='r1'][data-col='c1']").click
    find("input[data-row='r2'][data-col='c2']").click
    click_button 'Check Answer'

    expect(page).to have_css('.tjs-matrix__cell.correct-answer')
    expect(page).to have_css('.next-button', visible: :visible)
  end
end
