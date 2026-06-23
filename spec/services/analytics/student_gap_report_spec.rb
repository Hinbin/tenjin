# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Analytics::StudentGapReport do
  subject(:report) { described_class.call(student, classroom) }

  let(:subject_area) { create(:subject) }
  let(:classroom) { create(:classroom, subject: subject_area) }
  let(:topic_a) { create(:topic, subject: subject_area, name: 'Algorithms') }
  let(:topic_b) { create(:topic, subject: subject_area, name: 'Networks') }
  let(:student) { create(:student, school: classroom.school) }

  def student_stat(question, asked:, score:)
    create(:student_question_statistic, user: student, question: question,
                                        number_asked: asked, number_correct: score.to_i, score_sum: score)
  end

  describe 'topic breakdown' do
    let(:strong_q) { create(:question, topic: topic_a) }
    let(:weak_q) { create(:question, topic: topic_b) }

    before do
      student_stat(strong_q, asked: 10, score: 8.0) # Algorithms 0.8
      student_stat(weak_q, asked: 10, score: 2.0)   # Networks 0.2 (weakest)
    end

    it 'orders topics weakest first with mean scores' do
      breakdown = report.topic_breakdown

      expect(breakdown.pluck(:topic_name)).to eq(%w[Networks Algorithms])
      expect(breakdown.first).to include(topic_name: 'Networks', mean_score: 0.2, attempts: 10)
    end

    it 'ignores questions the student has never been asked' do
      create(:student_question_statistic, user: student, question: create(:question, topic: topic_a),
                                          number_asked: 0, number_correct: 0, score_sum: 0.0)

      expect(report.topic_breakdown.sum { |t| t[:attempts] }).to eq(20)
    end
  end

  describe 'cohort comparison' do
    let(:question) { create(:short_answer_question, topic: topic_a) }

    before do
      student_stat(question, asked: 10, score: 1.0) # student 0.1
      # Cohort breezes through it at 0.9 => student well below.
      create(:question_statistic, question: question, number_asked: 1000, number_correct: 900, score_sum: 900.0)
    end

    it 'places the student below the global cohort' do
      overall = report.cohort_comparison[:overall]

      expect(overall[:mastery]).to be_within(0.01).of(0.1)
      expect(overall[:cohort_mastery]).to be_within(0.01).of(0.9)
      expect(overall[:standing]).to eq(:below)
    end
  end

  describe 'priority gaps' do
    let(:cohort_easy) { create(:question, topic: topic_a, question_type: 'multiple') }
    let(:also_hard) { create(:short_answer_question, topic: topic_b) }

    before do
      # Student bombs a question the cohort finds easy => top priority gap.
      student_stat(cohort_easy, asked: 10, score: 1.0)
      create(:question_statistic, question: cohort_easy, number_asked: 1000, number_correct: 900, score_sum: 900.0)
      # Student also struggles, but so does the cohort => not a priority gap.
      student_stat(also_hard, asked: 10, score: 1.0)
      create(:question_statistic, question: also_hard, number_asked: 1000, number_correct: 150, score_sum: 150.0)
    end

    it 'surfaces questions the student trails the cohort on, biggest gap first' do
      gaps = report.priority_gaps

      expect(gaps.first).to include(question_id: cohort_easy.id, student_score: 0.1)
      expect(gaps.first[:cohort_score]).to be_within(0.01).of(0.9)
      expect(gaps.first[:gap]).to be_within(0.01).of(0.8)
      expect(gaps.pluck(:question_id)).not_to include(also_hard.id)
    end
  end

  describe 'strengths' do
    let(:hard_aced) { create(:short_answer_question, topic: topic_a) }
    let(:easy_aced) { create(:question, topic: topic_a, question_type: 'multiple') }

    before do
      # A genuinely hard question the student nails.
      student_stat(hard_aced, asked: 10, score: 9.0)
      create(:question_statistic, question: hard_aced, number_asked: 1000, number_correct: 100, score_sum: 100.0)
      # An easy question they also nail — not noteworthy, excluded.
      student_stat(easy_aced, asked: 10, score: 10.0)
      create(:question_statistic, question: easy_aced, number_asked: 1000, number_correct: 950, score_sum: 950.0)
    end

    it 'surfaces hard questions the student aced and skips easy ones' do
      strengths = report.strengths

      expect(strengths.pluck(:question_id)).to include(hard_aced.id)
      expect(strengths.pluck(:question_id)).not_to include(easy_aced.id)
      expect(strengths.first).to include(band: :hard)
      expect(strengths.first[:student_score]).to be >= described_class::STRENGTH_MIN_SCORE
    end
  end

  describe 'with no data' do
    it 'returns empty sections when the student has no statistics' do
      expect(report.topic_breakdown).to eq([])
      expect(report.priority_gaps).to eq([])
      expect(report.strengths).to eq([])
      expect(report.cohort_comparison[:overall][:standing]).to eq(:unknown)
    end
  end
end
