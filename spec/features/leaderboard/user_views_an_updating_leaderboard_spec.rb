require 'rails_helper'
require 'support/api_data'
require 'pry'

RSpec.describe 'User views an updating leaderboard', type: :feature, js: true do
  include_context 'default_creates'


  let(:new_entry) { create(:topic_score, topic: topic, school: school, score: 11) }

  before do
    setup_subject_database
    sign_in student
    student_topic_score
  end

  context 'when receiving updates' do
    before do
      one_to_nine
      visit(leaderboard_path(subject.name))
      find('p', text: student.forename)
    end

    it 'flashes an update if I have a score' do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css('tr#row-' + student.id.to_s + '.score-changed')
    end

    it 'flashes an update if someone else has a score' do
      Leaderboard::BroadcastLeaderboardPoint.new(TopicScore.where(user_id: User.second).first).call
      expect(page).to have_css("tr#row-#{User.second.id}.score-changed")
    end

    it 'receives two scores at the same time for different users' do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      Leaderboard::BroadcastLeaderboardPoint.new(TopicScore.where(user_id: User.second).first).call
      expect(page).to have_css("tr#row-#{student.id}.score-changed")
        .and have_css("tr#row-#{User.second.id}.score-changed")
    end

    it 'only displays 10 users after adding a new person' do
      Leaderboard::BroadcastLeaderboardPoint.new(new_entry).call
      expect(page).to have_no_css('tr:nth-child(11)')
    end

    it 'does not flash anyone when loaded' do
      # Make the default wait time shorter as the flash lasts a second
      expect(page).to have_no_css('tr.score-changed', wait: 0.5)
    end

    it 'only flashes once, for a second' do
      Leaderboard::BroadcastLeaderboardPoint.new(new_entry).call
      expect(page).to have_no_css('tr.score-changed', wait: 1.5)
    end

    it 're-ranks correctly' do
      Leaderboard::BroadcastLeaderboardPoint.new(new_entry).call
      expect(page).to have_css('tr:nth-child(2)#row-' + student.id.to_s)
    end
  end

  context 'with a school group' do
    before do
      create(:school, school_group: school.school_group)
      one_to_nine
      visit(leaderboard_path(subject.name))
      find('p', text: student.forename)
    end

    let(:student_another_school) { create(:student) }
    let(:student_same_school_group) { create(:student, school_group: student.school.school_group) }
    let(:another_name) { initialize_name User.second }

    it 'does not update if update is from an unaffiliated school group' do
      Leaderboard::BroadcastLeaderboardPoint.new(create(:topic_score, topic: topic)).call
      expect(page).to have_no_css('tr.score-changed')
    end

    it 'displays a new student with a score in the correct window' do
      Leaderboard::BroadcastLeaderboardPoint.new(new_entry).call
      expect(page).to have_css('tr#row-' + new_entry.user_id.to_s + '.score-changed')
    end

    it 'displays the name of a new student with a score ' do
      Leaderboard::BroadcastLeaderboardPoint.new(new_entry).call
      expect(page).to have_css('tr#row-' + new_entry.user_id.to_s, text: new_entry.user.forename)
    end

    it 'updates if score is from the same school group', :focus do
      binding.pry
      click_button('Select School')
      click_button('All')
      binding.pry
      Leaderboard::BroadcastLeaderboardPoint.new(create(:topic_score, topic: topic, school: second_school)).call
      expect(page).to have_css('tr.score-changed')
    end
  end

  context 'without a school group' do
    before do
      school.update_attribute(:school_group_id, nil)
      one_to_nine
      visit(leaderboard_path(subject.name))
      find('p', text: student.forename)
    end

    it 'updates if someone from the same schools has a score' do
      Leaderboard::BroadcastLeaderboardPoint.new(TopicScore.second).call
      expect(page).to have_css("tr#row-#{TopicScore.second.user.id}.score-changed")
    end

    it 'updates me when I have a score' do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css("tr#row-#{student.id}.score-changed")
    end
  end

  context 'when showing for a specific subject' do
    before do
      one_to_nine
      visit(leaderboard_path(subject.name))
      find('p', text: student.forename)
    end

    let(:different_subject) { create(:subject) }
    let(:different_subject_score) { create(:topic_score, school: school, score: 11, subject: different_subject) }

    it 'does not update for a different subject' do
      Leaderboard::BroadcastLeaderboardPoint.new(different_subject_score).call
      expect(page).to have_no_css('tr.score-changed')
    end
  end

  context 'when viewing a single topic' do
    before do
      one_to_nine
      visit(leaderboard_path(subject.name, topic: Topic.first))
      find('p', text: student.forename)
    end

    let(:different_topic) { create(:topic, subject: subject) }
    let(:different_topic_score) { create(:topic_score, school: school, score: 11, topic: different_topic) }

    it 'updates for the current topic' do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css('tr.score-changed')
    end

    it 'updates with the topic score and not the total score' do
      different_topic_score
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score).call
      expect(page).to have_css('td', exact_text: student_topic_score.score)
    end

    it 'does not update for a different topic' do
      Leaderboard::BroadcastLeaderboardPoint.new(different_topic_score).call
      expect(page).to have_no_css('tr.score-changed')
    end
  end
end
