require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User views the leaderboard', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
  end

  context 'when selecting a leaderboard to view' do
    let(:second_subject) { create(:subject) }
    let(:second_classroom) { create(:classroom, subject: second_subject, school: school) }
    let(:second_subject_map) { create(:subject_map, school: school, subject: second_subject) }

    before do
      topic
      second_subject_map
      create(:enrollment, classroom: second_classroom, user: student)
      visit leaderboard_index_path
    end

    it 'lets me pick the topic score for a subject' do
      click_link(subject.name)
      click_link(topic.name)
      expect(page).to have_css('h3', text: topic.name) && have_css('h1', text: subject.name)
    end

    it 'lets me pick the overall score for the subject' do
      click_link(subject.name)
      click_link('All')
      expect(page).to have_css('h3', text: 'All') && have_css('h1', text: subject.name)
    end

    it 'lets me pick from multiple subjects' do
      click_link(second_subject.name)
      click_link('All')
      expect(page).to have_css('h3', text: 'All') && have_css('h1', text: second_subject.name)
    end
  end

  context 'when viewing a leaderboard' do
    before do
      create(:topic_score, topic: topic, user: student)
    end

    let(:student_name) { student.forename + ' ' + student.surname[0] }
    let(:another_name) { User.second.forename + ' ' + User.second.surname[0] }

    it 'displays myself if I have a score' do
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td', exact_text: student_name)
    end

    it 'displays others if they have a score' do
      create_list(:topic_score, 10, topic: topic, school: school)
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td', exact_text: another_name)
    end

    it 'allows me include students in the same school group' do
    end

    it 'paginates to show the 50 around me'
    it 'allows me to see the top 50'
    it 'defaults to a weekly leaderboard'
    it 'allows me to see an all time leaderboard'
  end
end
