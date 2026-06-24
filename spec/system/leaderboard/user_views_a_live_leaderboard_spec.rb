# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User views an updating leaderboard', :default_creates, :js,
               type: :system do
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
    let(:student_same_school) { create(:student, school: school) }
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

    it 'resets all scores to 0 when live leaderboard selected' do
      # wait_for_ajax
      expect(page).to have_css('tbody tr', count: 0)
    end

    it 'shows live updates from my own school' do
      topic_score_different_classroom
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_different_classroom, student_same_school).call
      expect(page).to have_css("#leaderboardTable tbody tr#row-#{student_same_school.id}")
    end

    # Live ticks are scoped per school (LeaderboardChannel): a broadcast for another school in the
    # trust must NOT reach this viewer. Other-school rows are filled in (pseudonymised) by the AJAX
    # reload, not by live broadcasts.
    it 'does not live-tick students from another school in the trust' do
      click_button('All')
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, second_student).call
      expect(page).to have_no_css("#leaderboardTable tbody tr#row-#{second_student.id}")
    end

    it 'allows you to filter by class' do
      click_button('Select Class')
      click_button(enrollment_different_classroom.classroom.name)
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_different_classroom,
                                                 topic_score_different_classroom.user).call
      expect(page).to have_css('.score-changed').and have_css('tbody tr', count: 1)
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
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score, student_topic_score.user).call
      expect(page).to have_css('tr.score-changed')
    end

    it 'calculates the score correctly' do
      student_topic_score.update_attribute('score', student_topic_score.score + add_score)
      student_topic_score.reload
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score.topic, student_topic_score.user).call
      expect(page).to have_css('td', exact_text: add_score.to_s)
    end
  end
end
