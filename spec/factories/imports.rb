# frozen_string_literal: true

FactoryBot.define do
  factory :import do
    topic
    filename { 'questions.csv' }
    token_label { 'test-token' }
    imported_count { 0 }
    skipped_count { 0 }
    updated_count { 0 }
    import_errors { [] }
  end
end
