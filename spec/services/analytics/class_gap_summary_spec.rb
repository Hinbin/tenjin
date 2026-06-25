# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Analytics::ClassGapSummary do
  subject(:summary) { described_class.call(classroom) }

  let(:subject_area) { create(:subject) }
  let(:classroom) { create(:classroom, subject: subject_area) }
  let(:topic) { create(:topic, subject: subject_area) }
  let(:question) { create(:question, topic: topic) }
  let(:alice) { create(:student, school: classroom.school) }
  let(:bob) { create(:student, school: classroom.school) }

  def enrol(user)
    Enrollment.create!(classroom: classroom, user: user)
  end

  before do
    enrol(alice)
    enrol(bob)
  end

  it 'counts enrolled students and how many have practiced in the subject' do
    create(:student_question_statistic, user: alice, question: question, number_asked: 5,
                                        number_correct: 3, score_sum: 3.0)

    expect(summary.student_count).to eq(2)
    expect(summary.students_active).to eq(1)
  end

  it 'returns zero active when nobody has practiced' do
    expect(summary.student_count).to eq(2)
    expect(summary.students_active).to eq(0)
  end

  it 'handles a classroom with no subject' do
    no_subject = described_class.call(create(:classroom, subject: nil))

    expect(no_subject.student_count).to eq(0)
    expect(no_subject.students_active).to eq(0)
  end
end
