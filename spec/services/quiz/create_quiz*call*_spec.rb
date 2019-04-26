require 'rails_helper'

RSpec.describe Quiz::CreateQuiz, '#call' do
  include_context 'default_creates'

  context 'when creating a lucky dip' do
    let(:quiz) { Quiz::CreateQuiz.new(user: student, topic: 'Lucky Dip', subject: subject).call }
    let(:quiz_with_topic) { Quiz::CreateQuiz.new(user: student, topic: topic.id, subject: subject).call }
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

    it 'does not have a topic for a lucky dip quiz' do
      expect(quiz.topic).to eq(nil)
    end

    it 'sets the topic id for a non-lucky dip quiz' do
      expect(quiz_with_topic.topic).to eq(topic)
    end
  end
end
