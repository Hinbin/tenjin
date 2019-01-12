require 'pry'
RSpec.describe 'User changes leaderboard options', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
    create(:topic_score, topic: topic, user: student)
  end

  context 'with no school group' do
    let(:student) { create(:student, school: school_without_school_group) }

    it 'hides the school group option' do
      School.first.update_attribute(:school_group_id, nil)
      visit(leaderboard_path(subject.name))
      find(:css, '#optionFlex').click
      expect(page).to have_no_css('label', text: 'All Schools')
    end
  end

  context 'with a school group' do
    before do
      create(:topic_score, school: second_school, topic: topic)
      visit(leaderboard_path(subject.name))
      find(:css, '#optionFlex').click
    end

    it 'shows only my school by default' do
      expect(page).to have_css('table#leaderboardTable tr', count: 2)
    end

    it 'allows me to toggle to just my school' do
      find(:css, '#schoolOnly').click
      expect(page).to have_css('table#leaderboardTable tr', count: 2)
    end

    it 'allows me to toggle to all schools' do
      find(:css, '#schoolGroup').click
      expect(page).to have_css('table#leaderboardTable tr', count: 3)
    end

    it 'allows me to toggle back to viewing the school group from my school' do
      find(:css, '#schoolGroup').click
      find(:css, '#schoolOnly').click
      expect(page).to have_css('table#leaderboardTable tr', count: 2)
    end
  end

  context 'when viewing the top 50' do
    before do
      create_list(:topic_score, 50, school: school, topic: topic)
      visit(leaderboard_path(subject.name))
      find(:css, '#optionFlex').click
    end

    it 'allows me to see the top 50' do
      find(:css, '#top50').click
      expect(page).to have_css('table#leaderboardTable tr', count: 51)
    end

    it 'allows me to see myself only after viewing the top 50' do
      find(:css, '#top50').click
      find(:css, '#myPosition').click
      expect(page).to have_css('table#leaderboardTable tr', count: 11)
    end
  end

  it 'allows me to see an all time leaderboard'
  it 'defaults to a weekly leaderboard'
end
