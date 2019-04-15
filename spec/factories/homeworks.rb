FactoryBot.define do
  factory :homework do
    classroom
    topic
    due_date { DateTime.now + 1.week }
    required { rand(0..100) }
  end
end
