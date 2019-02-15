require 'rails_helper'

RSpec.describe Quiz::CreateQuiz, '#call' do
  include_context 'default_creates'

  context 'when creating a lucky dip' do
    let(:quiz) { Quiz::CreateQuiz.new(user: student, topic: 'Lucky Dip', subject: subject).call }
    let(:topics) { create_list(:topic, 10, subject: subject) }

    before do
      topics.each do |t|
        create(:question, topic: t)
      end
    end

    it 'has 10 questions' do
      expect(quiz.questions.count).to eq(10)
    end

    it 'creates a lucky dip' do
      expect(quiz.questions.first.topic).not_to eq(quiz.questions.second.topic)
    end
  end
end
