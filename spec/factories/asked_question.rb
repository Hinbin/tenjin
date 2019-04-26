FactoryBot.define do
  factory :asked_question do
    transient do
      user { nil }
    end

    question
    association :quiz, factory: :quiz, user: nil, strategy: :build

    correct { nil }

    after(:build) do |asked_question, evaluator|
      if evaluator.user.nil?
        asked_question.user = create(:student)
      else
        asked_question.quiz.user = evaluator.user
      end
    end
  end
end
