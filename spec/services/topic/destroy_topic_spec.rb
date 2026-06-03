# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Topic::DestroyTopic, :default_creates do
  let(:lesson) { create(:lesson, topic:) }
  let(:question_with_lesson) { create(:question, topic:, lesson:) }
  let(:quiz_with_lesson) { create(:quiz, user: student, subject:, topic:, lesson:) }
  let(:homework_with_lesson) { create(:homework, classroom:, topic:, lesson:) }
  let(:usage_statistic) { create(:usage_statistic, user: student, topic:, lesson:) }
  let(:challenge) { create(:challenge, topic:) }

  before do
    question_with_lesson
    create(:asked_question, question: question_with_lesson, quiz: quiz_with_lesson)
    create(:homework_progress, homework: homework_with_lesson, user: student)
    create(:challenge_progress, challenge:, user: student)
    usage_statistic
  end

  it 'deletes a heavily used topic without lesson foreign-key failures' do
    result = described_class.call(topic)

    expect(result).to be_success
    expect(Topic.exists?(topic.id)).to be false
    expect(Lesson.exists?(lesson.id)).to be false
    expect(Homework.exists?(homework_with_lesson.id)).to be false
    expect(Quiz.exists?(quiz_with_lesson.id)).to be false
    expect(Question.exists?(question_with_lesson.id)).to be false
    expect(Challenge.exists?(challenge.id)).to be false
  end

  it 'preserves usage statistics while clearing deleted topic and lesson references' do
    described_class.call(topic)

    expect(usage_statistic.reload.topic_id).to be_nil
    expect(usage_statistic.lesson_id).to be_nil
  end
end
