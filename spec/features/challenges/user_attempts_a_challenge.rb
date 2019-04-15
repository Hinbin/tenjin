RSpec.describe 'User attempts a challenge', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
  end

  context 'when looking at the challenges' do
    let(:challenge_single_question) { create(:challenge, topic: topic, challenge_type: 'number_correct', number_required: 1, end_date: DateTime.now + 1.hour) }
    let(:second_subject) { create(:subject) }
    let(:second_topic) { create(:topic, subject: second_subject) }
    let(:challenge_two) { create(:challenge, topic: create(:topic, subject: subject)) }
    let(:question) { create(:question, topic: topic) }
    let(:answer) { create(:answer, question: question, correct: true) }
    let(:progressed_challenge) { create(:challenge_progress, user: student, challenge: challenge_one, progress: 70) }
    let(:completed_challenge) { create(:challenge_progress, user: student, challenge: challenge_one, progress: 100, completed: true) }
    let(:quiz) { create(:new_quiz) }

    before do
      challenge_single_question
      answer
    end

    it 'links you to the correct quiz when clicked' do
      visit(dashboard_path)
      find(:css, '#challenge-table tbody tr:nth-child(1)').click
      expect(page).to have_css('p', exact_text: challenge_one.topic.name)
    end

    it 'allows me to answer a question after creating a quiz from a challenge' do # turbolinks bug 
      visit(dashboard_path)
      find(:css, '#challenge-table tbody tr:nth-child(1)').click
      first(class: 'question-button').click
      expect(page).to have_text('Next Question')
    end

    it 'lets me complete a number of points required challenge' do
      visit(dashboard_path)
      find(:css, '#challenge-table tbody tr:nth-child(1)').click
      first(class: 'question-button').click
      first(class: 'next-button').click
    end
  end
end
