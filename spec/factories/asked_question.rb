# frozen_string_literal: true

FactoryBot.define do
  factory :asked_question do
    transient do
      user { nil }
    end

    question
    association :quiz, factory: :quiz, user: nil, strategy: :build

    correct { nil }

    after(:build) do |asked_question, evaluator|
      asked_question.quiz.user = if evaluator.user.nil?
                                   create(:student)
                                 else
                                   evaluator.user
                                 end
    end
  end
end
