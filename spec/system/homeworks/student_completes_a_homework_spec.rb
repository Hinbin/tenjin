# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Student completes a homework', type: :system, js: true, default_creates: true do
  before do
    setup_subject_database
    sign_in student
  end

  context 'when looking at the challenges' do
    let(:homework_ten_percent) { create(:homework, topic: topic, classroom: classroom, required: 10) }
    let(:quiz) { create(:new_quiz) }

    before do
      homework_ten_percent
      answer
    end

    it 'lets me complete a homework' do
      visit(dashboard_path)
      find(:css, '.homework-row[data-homework="' + homework_ten_percent.id.to_s + '"]').click
      first(class: 'question-button').click
      first(class: 'next-button').click
      expect(page).to have_css('.homework-row > td > svg.fa-check')
    end
  end

  context 'when completing a lesson homework' do
    it 'only gives questions assigned to that lesson'
    it 'awards points for the first try only'
    it 'prevents further access when homework completed'
  end
end
