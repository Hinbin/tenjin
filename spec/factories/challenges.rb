FactoryBot.define do
  factory :challenge do
    challenge_type { 'full_marks' }
    start_date { DateTime.now }
    end_date { DateTime.now + 7.days }
    points { 10 }
    topic
  end
end
