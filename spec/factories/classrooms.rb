# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    name { FFaker::AddressUK.street_address }
    description { FFaker::AddressUK.street_name }
    code { FFaker::AddressUK.postcode }
    sequence(:client_id) { |n| "classroom #{n}" }
    disabled { false }
    subject
    school

    factory :classroom_with_students do
      transient do
        student_count { 2 }
      end

      after(:create) do |classroom, evaluator|
        students = create_list(:student, evaluator.student_count, school: classroom.school)
        students.each { |s| create(:enrollment, user: s, classroom: classroom) }
        classroom.reload
      end
    end
  end
end
