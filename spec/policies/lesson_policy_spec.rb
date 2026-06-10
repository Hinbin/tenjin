# frozen_string_literal: true

require "rails_helper"

RSpec.describe LessonPolicy, :default_creates do
  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(student, Lesson).resolve }

    let!(:enrolled_lesson) { create(:lesson, topic: topic) }
    let!(:unenrolled_lesson) { create(:lesson) }
    let!(:enrollment) { create(:enrollment, user: student, classroom: classroom) }

    it "includes lessons in enrolled subjects" do
      expect(resolved).to include(enrolled_lesson)
    end

    it "excludes lessons in unenrolled subjects" do
      expect(resolved).not_to include(unenrolled_lesson)
    end
  end
end
