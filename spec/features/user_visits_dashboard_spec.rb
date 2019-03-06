RSpec.describe 'User visits dashboard', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
  end

  context 'when looking at the dashboard' do
    it 'shows how many points I have'
  end

  context 'when using the quiz section' do
    it 'can start a quiz'
  end

  context 'when looking at the challenges' do
    let(:challenge_one) { create(:challenge, topic: topic) }
    let(:second_subject) { create(:subject) }
    let(:second_topic) { create(:topic, subject: second_subject) }
    let(:challenge_two) { create(:challenge, topic: create(:topic, subject: subject)) }
    let(:question) {create(:question, topic: topic)}

    before do
      challenge_one
      challenge_two
      create(:answer, question: question, correct: true)
    end

    it 'shows challenges for subjects I am subscribed to' do
      visit(dashboard_path)
      expect(page).to have_content(Challenge.stringify(challenge_one))
    end

    it 'only shows challenges for subjects I am subscribed to' do
      second_topic
      c = Challenge.create_challenge(second_subject)
      visit(dashboard_path)
      expect(page).not_to have_content(Challenge.stringify(c))
    end

    it 'has a live countdown'

    it 'links you to the correct quiz when clicked' do
      visit(dashboard_path)
      find(:css, '#challenge-table tbody tr:nth-child(1)').click
      expect(page).to have_css('p', exact_text: challenge_one.topic.name)
    end
  end
end
