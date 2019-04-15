FactoryBot.define do
  factory :homework_progress do
    homework 
    user
    progress { rand(0..100) }
    completed { rand(0..1) }
  end
end
