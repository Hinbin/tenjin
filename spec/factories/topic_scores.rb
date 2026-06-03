# frozen_string_literal: true

FactoryBot.define do
  factory :topic_score do
    transient do
      school { nil }
      existing_users { false }
      topic_in_subject { nil }
    end

    score { rand(1000) }
    association :user, factory: :student, school: nil, strategy: :build
    association :topic, strategy: :build

    factory :ordered_topic_score do
      sequence(:score)
    end

    after(:build) do |topic_score, evaluator|
      if evaluator.topic_in_subject.present?
        topic_score.topic = Topic.find(Topic.where(active: true, subject: evaluator.topic_in_subject).pluck(:id).sample)
      end

      if evaluator.existing_users && evaluator.school.present?
        topic_score.user = User.find(User.where(school: evaluator.school).pluck(:id).sample)
      elsif evaluator.existing_users
        topic_score.user = User.find(User.pluck(:id).sample)
      else
        topic_score.user.school = if evaluator.school.nil? && topic_score.user.school.nil?
                                    create(:school)
                                  elsif evaluator.school.nil?
                                    topic_score.user.school
                                  else
                                    evaluator.school
                                  end
      end
      topic_score.save
    end
  end
end
