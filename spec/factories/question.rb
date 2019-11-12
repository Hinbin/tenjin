# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    sequence(:question_text) { |n| FFaker::Lorem.sentence + n.to_s }
    question_type { 'multiple' }
    topic
    active { true }
    lesson { nil }

    factory :short_answer_question do
      question_type { 'short_answer' }
    end

    factory :boolean_question do
      question_type { 'boolean' }
      after(:build) do |q|
        q.answers.first.update_attribute(:text, 'true')
        q.answers << create(:answer, question: q, text: 'false')
      end
    end

    factory :question_with_lesson do
      lesson
    end

    after(:build) { |question| question.answers << create(:answer, question: question, correct: true) }
  end
end
