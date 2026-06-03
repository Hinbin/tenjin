# frozen_string_literal: true

FactoryBot.define do
  ## TODO - make the school be the same for the classroom and the user
  factory :enrollment do
    transient do
      school { nil }
    end

    # Make sure we only create one school, and use the same school for the
    # classroom as the user.

    association :classroom, school: nil, strategy: :build
    association :user, factory: :student, school: nil, strategy: :build

    after(:build) do |enrollment, evaluator|
      if evaluator.school.nil?
        enrollment.classroom = create(:classroom) unless enrollment.classroom.persisted?
        enrollment.user = create(:user, school: enrollment.classroom.school) unless enrollment.user.persisted?
        enrollment.classroom.save
      else
        enrollment.user = create(:student, school: evaluator.school) if enrollment.user.new_record?
        enrollment.classroom = create(:classroom, school: evaluator.school) if enrollment.classroom.new_record?
      end

      enrollment.save
    end
  end
end
