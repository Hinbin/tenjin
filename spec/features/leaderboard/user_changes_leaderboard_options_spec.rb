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
      expect(page).to have_no_button('Select School')
    end
  end

  context 'with a school group' do
    before do
      create(:topic_score, school: second_school, topic: topic)
      visit(leaderboard_path(subject.name))
    end

    it 'shows only my school by default' do
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 1)
    end

    it 'allows me to toggle to just my school' do
      click_button('Select School')
      click_button(student.school.name)
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 1)
    end

    it 'allows me to toggle to all schools' do
      click_button('Select School')
      click_button('All')
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 2)
    end

    it 'allows me to toggle back to viewing the school group from my school,' do
      click_button('Select School')
      click_button('All')
      click_button('All')
      click_button(student.school.name)
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 1)
    end
  end

  context 'when viewing all users' do
    before do
      create_list(:topic_score, 50, school: school, topic: topic)
      visit(leaderboard_path(subject.name))
    end

    it 'allows me to see all entries' do
      find(:css, 'table#leaderboardTable tbody tr:nth-child(10)')
      find(:css, '#showAll label').click
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 51)
    end

    it 'allows me to see myself only after viewing all entries' do
      find(:css, '#showAll label').click
      find(:css, 'table#leaderboardTable tbody tr:nth-child(51)')
      find(:css, '#showAll label').click
      expect(page).to have_css('table#leaderboardTable tbody tr', count: 10)
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

  context 'when filtering by classroom' do
    let(:overall_score) { (AllTimeTopicScore.first.score + TopicScore.first.score).to_s }
    let(:second_topic) { create(:topic, subject: subject) }
    let(:enrollment_classroom) { create(:enrollment, classroom: second_classroom, user: second_student) }
    let(:second_classroom) { create(:classroom, subject: subject, school: school) }
    let(:second_student) { create(:student, school: student.school) }
    let(:topic_score_different_classroom) { create(:topic_score, user: second_student, subject: subject) }
    let(:different_school_same_classroom_name) { create(:classroom, name: second_classroom.name, school: second_school) }
    let(:different_school_enrollment) { create(:enrollment, classroom: different_school_same_classroom_name) }
    let(:different_school_topic_score) { create(:topic_score, subject: subject, user: different_school_enrollment.user)}
    let(:same_name_different_school) do
      different_school_enrollment
      different_school_topic_score
    end

    before do
      topic_score_different_classroom
      enrollment_classroom
      second_school
      second_classroom
      visit(leaderboard_path(subject.name))
    end

    it 'shows different classrooms by default' do
      expect(page).to have_css('#leaderboardTable tbody tr', count: 2)
    end

    it 'filters by classroom' do
      click_button('Select Class')
      click_button(second_classroom.name)
      expect(page).to have_css('#leaderboardTable tbody tr', count: 1)
    end

    it 'changes school back to users when selected' do
      click_button('Select School')
      click_button(second_school.name)
      click_button('Select Class')
      click_button(second_classroom.name)
      expect(page).to have_button('Select School')
    end

    it 'filters classrooms with the same name in another school out' do
      same_name_different_school
      visit(leaderboard_path(subject.name))
      click_button('Select Class')
      click_button(second_classroom.name)
      expect(page).to have_css('#leaderboardTable tbody tr', count: 1)
    end
  end
end
