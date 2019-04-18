FactoryBot.define do
  factory :homework do
    classroom
    topic
    due_date { rand((DateTime.now + 1.day)..(DateTime.now + 1.week)) }
    required { rand(0..100) }
  end
end
