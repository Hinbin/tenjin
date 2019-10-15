require 'rails_helper'
require 'support/api_data'
require 'pry'

RSpec.describe 'User views an updating leaderboard', type: :feature, default_creates: true, js: true do

  before do
    setup_subject_database
    student_topic_score
    one_to_nine
  end

  it 'does not show the option for a student' do
    sign_in student
    visit(leaderboard_path(subject.name))
    expect(page).to have_no_css('#toggleLive')
  end

  it 'shows the option for a school_admin' do
    sign_in school_admin
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('#toggleLive')
  end

  context 'with a school group' do
    let(:second_student) { create(:student, school: second_school) }
    let(:second_school) { create(:school, school_group: school.school_group) }
    let(:topic_score_same_school_group) { create(:topic_score, score: 100, topic: topic, user: second_student) }
    let(:student_same_school) { create(:student, school: school )}
    let(:enrollment_different_classroom) do 
      create(:enrollment, 
             user: student_same_school, 
             classroom: create(:classroom, subject: subject, school: school))
    end
    let(:topic_score_different_classroom) { create(:topic_score, score: 100, topic: topic, user: student_same_school) }

    before do
      second_school
      enrollment_different_classroom
      sign_in teacher
      topic_score_same_school_group
      visit(leaderboard_path(subject.name))
      find(:css, '#leaderboardTable tbody tr:nth-child(10)')
      find(:css, '#toggleLive label', visible: false).click
    end

    it 'shows updates from own school only by default' do
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group).call
      expect(page).to have_no_css('#leaderboardTable tbody tr')
    end

    it 'shows updates from other schools when selected' do
      topic_score_same_school_group.update_attribute('score', 110)
      click_button(school.name)
      click_button('All')
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group).call
      expect(page).to have_css("#leaderboardTable tbody tr td#score-#{topic_score_same_school_group.user.id}", exact_text: 10)
    end

    it 'allows you to filter by class' do
      click_button('Select Class')
      click_button(enrollment_different_classroom.classroom.name)
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_different_classroom).call
      expect(page).to have_css('.score-changed').and have_css('tbody tr', count: 1)
    end

    it 'allows you to filter by school' do
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group).call
      click_button(school.name)
      click_button(topic_score_same_school_group.user.school.name)
      expect(page).to have_css('tbody tr', count: 1)
    end
  end

  context 'when an employee' do
    let(:add_score) { rand(0..1000) }

    before do
      sign_in teacher
      visit(leaderboard_path(subject.name))
      find(:css, '#leaderboardTable tbody tr:nth-child(10)')
      find(:css, '#toggleLive label').click
    end

    it 'shows the option or a school admin or employee' do
      expect(page).to have_css('#toggleLive')
    end

    it 'resets all scores to zero' do
      expect(page).to have_no_css('tbody tr')
    end

    it 'shows weekly scores when turned off' do
      find(:css, '#toggleLive label').click
      expect(page).to have_css('tbody tr', count: 10)
    end

    it 'shows an update after being turned on' do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css('tr.score-changed')
    end

    it 'calculates the score correctly' do
      student_topic_score.update_attribute('score', student_topic_score.score + add_score)
      student_topic_score.reload
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css('td', exact_text: add_score.to_s)
    end
  end
end
