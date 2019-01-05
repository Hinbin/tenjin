require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User views the leaderboard', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
  end

  context 'when viewing a leaderboard' do
    before do
      create(:topic_score, topic: topic, user: student)
    end

    let(:student_name) { initialize_name student }
    let(:another_name) { initialize_name User.second }
    let(:one_to_ten) do
      (1..10).each do |n|
        create(:topic_score, topic: topic, school: school, score: n)
      end
    end

    it 'displays myself if I have a score' do
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td', exact_text: student_name)
    end

    it 'puts the scores in order' do
      TopicScore.first.update(score: 5)
      student.update(forename: 'Aaron') # Ensure first alphabetically
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr:nth-child(6)', text: student_name)
    end

    it 'displays others if they have a score' do
      create_list(:topic_score, 8, topic: topic, school: school)
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td', exact_text: another_name)
    end

    it 'shows me what position I am in within the school' do
      TopicScore.first.update(score: 5)
      student.update(forename: 'Aaron') # Ensure first alphabetically
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr', text: ('6 ' + student_name).to_s)
    end

    it 'does not show students from another school' do
      create(:topic_score, topic: topic)
      visit(leaderboard_path(subject.name))
      expect(page).to have_no_css('td', exact_text: another_name)
    end

    it 'defaults to show 10 entries' do
      TopicScore.first.update(score: 5)
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('table#leaderboardTable tr', count: 11)
    end

    it 'shows the top 10 if I have no score' do
      TopicScore.first.destroy
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr:nth-child(10) td', exact_text: '10')
    end

    it 'shows me when I am at the top of the table' do
      TopicScore.first.update(score: 50)
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('table#leaderboardTable tr', count: 11)
    end

    it 'shows me when I am at the bottom of the table' do
      TopicScore.first.update(score: 0)
      one_to_ten
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('table#leaderboardTable tr', count: 11)
    end
    it 'hides schools on a small screen'

    context 'when viewing a subjects overall score' do
      let(:second_topic_score) { create(:topic_score, user: student, topic: create(:topic, subject: Subject.first)) }
      let(:second_subject_score) { create(:topic_score, user: student, topic: create(:topic)) }
      let(:overall_total) { TopicScore.first.score + TopicScore.second.score }

      it 'adds up scores from different topics' do
        second_topic_score
        visit(leaderboard_path(subject.name))
        expect(page).to have_css('tr.bg-dark td:nth-child(4)', exact_text: overall_total)
      end

      it 'ignores scores from topics of a different subject'
    end

    context 'when part of a school group' do
      let(:second_school) { create(:school, school_group: School.first.school_group) }
      let(:second_school_student) { User.where(school: second_school).first }
      let(:second_school_student_name) { initialize_name second_school_student }

      it 'allows me to view students in the same school group' do
        create(:topic_score, topic: topic, school: second_school)
        visit(leaderboard_path(subject.name))
        expect(page).to have_css('td', exact_text: second_school_student_name)
      end

      it 'allows me to toggle between viewing my school and viewing the school group'
    end

    it 'allows me to see the top 50'
    it 'defaults to a weekly leaderboard'
    it 'allows me to see an all time leaderboard'
  end
end
