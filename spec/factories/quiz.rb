FactoryBot.define do
  factory :quiz do
    time_last_answered { rand(5).minute.ago }
    num_questions_asked { 0 }
    streak { rand(num_questions_asked) }
    answered_correct { rand(streak..num_questions_asked) }
    active { true }

    user
    subject
  end
end
