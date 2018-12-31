FactoryBot.define do
  factory :topic_score do
    transient do
      school { nil }
    end
    score { rand(1000) }
    association :user, factory: :student, school: nil, strategy: :build
    association :topic, factory: :topic

    after(:build) do |topic_score, evaluator|
      topic_score.user.school = if evaluator.school.nil? && topic_score.user.school.nil?
                                  create(:school)
                                elsif evaluator.school.nil?
                                  topic_score.user.school
                                else
                                  evaluator.school
                                end

      topic_score.save
    end
  end
end
