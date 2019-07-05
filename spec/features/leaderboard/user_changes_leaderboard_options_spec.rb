RSpec.describe 'User changes leaderboard options', type: :feature, js: true, default_creates: true do

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

    it 'allows me to toggle back to viewing the school group from my school,' do
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

  context 'when viewing the all time leaderboard' do
    let(:overall_score) { (AllTimeTopicScore.first.score + TopicScore.first.score).to_s }
    let(:second_topic) { create(:topic, subject: subject) }
    let(:second_subject_topic) { create(:topic) }
    let(:second_student) { create(:student, school: student.school) }

    before do
      create(:all_time_topic_score, user: student, topic: topic)
      visit(leaderboard_path(subject.name))
      find(:css, '#optionFlex').click
    end

    it 'adds up the the overall score correctly' do
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: overall_score)
    end

    it 'adds up a subject score accross multiple topics correctly' do
      create(:all_time_topic_score, user: student, topic: second_topic)
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: (TopicScore.first.score +
                                                  AllTimeTopicScore.first.score +
                                                  AllTimeTopicScore.second.score).to_s)
    end

    it 'defaults to a weekly leaderboard' do
      expect(page).to have_css('td', exact_text: TopicScore.first.score)
    end

    it 'adds up scores only for that subject' do
      create(:all_time_topic_score, user: student, topic: second_subject_topic)
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: TopicScore.first.score)
    end

    it 'adds up scores only for that topic' do
      create(:all_time_topic_score, user: student, topic: second_topic)
      visit(leaderboard_path(subject.name, topic: second_topic))
      find(:css, '#optionFlex').click
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: AllTimeTopicScore.second.score)
    end

    it 'adds up scores correctly for another user if I have no score' do
      AllTimeTopicScore.first.destroy
      create(:all_time_topic_score, user: second_student, topic: second_topic)
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: AllTimeTopicScore.first.score)
    end

    it 'works if there is only an all time score and no topic score' do
      TopicScore.first.destroy
      find(:css, '#allTime').click
      expect(page).to have_css('td', exact_text: AllTimeTopicScore.first.score)
    end
  end
end
