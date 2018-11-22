FactoryBot.define do
  ## TODO - make the school be the same for the classroom and the user
  factory :enrollment do
    association :classroom, factory: :classroom
    association :user, factory: :user
  end
end
