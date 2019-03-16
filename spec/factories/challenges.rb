FactoryBot.define do
  factory :challenge do
    challenge_type { Challenge.challenge_types.values.sample }
    number_required { rand(4..10) }
    start_date { DateTime.now }
    end_date { DateTime.now + 7.days }
    points { 10 }
    topic
  end
end
