FactoryBot.define do
  factory :quiz do
    time_last_answered { rand(5).minute.ago }
    num_questions_asked { rand(1..50) }
    streak { rand(num_questions_asked) }
    answered_correct { rand(streak..num_questions_asked) }
    active { true }
    topic { nil }
    question_order { (0..num_questions_asked).to_a.shuffle }

    user
    subject

    factory :new_quiz do
      num_questions_asked { 0 }
    end
  end
end
