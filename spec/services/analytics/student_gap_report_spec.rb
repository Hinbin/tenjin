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

  describe 'topic gap grid' do
    let(:strong_q) { create(:question, topic: topic_a) }
    let(:weak_q) { create(:question, topic: topic_b) }

    before do
      # Algorithms: student 0.8 vs cohort 0.2 (above). Networks: student 0.2 vs cohort 0.8 (below).
      student_stat(strong_q, asked: 10, score: 8.0)
      student_stat(weak_q, asked: 10, score: 2.0)
      create(:question_statistic, question: strong_q, number_asked: 100, number_correct: 20, score_sum: 20.0)
      create(:question_statistic, question: weak_q, number_asked: 100, number_correct: 80, score_sum: 80.0)
    end

    it 'orders topics most below the cohort first, carrying cohort-relative standing and attempts' do
      grid = report.topic_gap_grid

      expect(grid.pluck(:topic_name)).to eq(%w[Networks Algorithms])
      expect(grid.first).to include(topic_name: 'Networks', standing: :below, attempts: 10)
      expect(grid.last).to include(topic_name: 'Algorithms', standing: :above)
      expect(grid.first[:delta]).to be < grid.last[:delta]
    end

    it 'does not carry the class grid student-count column' do
      expect(report.topic_gap_grid.first).not_to include(:students)
    end

    it 'ignores questions the student has never been asked' do
      create(:student_question_statistic, user: student, question: create(:question, topic: topic_a),
                                          number_asked: 0, number_correct: 0, score_sum: 0.0)

      expect(report.topic_gap_grid.sum { |t| t[:attempts] }).to eq(20)
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

  describe 'lesson drill-down within a topic' do
    let(:strong_lesson) { create(:lesson, topic: topic_a, title: 'Sorting') }
    let(:weak_lesson) { create(:lesson, topic: topic_a, title: 'Recursion') }
    let(:strong_q) { create(:question, topic: topic_a, lesson: strong_lesson) }
    let(:weak_q) { create(:question, topic: topic_a, lesson: weak_lesson) }

    before do
      # Sorting: student 0.9 vs cohort 0.5 (above). Recursion: student 0.3 vs cohort 0.5 (below).
      student_stat(strong_q, asked: 10, score: 9.0)
      student_stat(weak_q, asked: 10, score: 3.0)
      create(:question_statistic, question: strong_q, number_asked: 100, number_correct: 50, score_sum: 50.0)
      create(:question_statistic, question: weak_q, number_asked: 100, number_correct: 50, score_sum: 50.0)
    end

    def algorithms_lessons
      report.topic_gap_grid.find { |row| row[:topic_name] == 'Algorithms' }[:lessons]
    end

    it 'breaks a topic cell down by lesson, weakest first, with cohort-relative standing' do
      lessons = algorithms_lessons

      expect(lessons.pluck(:lesson_name)).to eq(%w[Recursion Sorting])
      expect(lessons.first).to include(lesson_name: 'Recursion', standing: :below, attempts: 10, questions: 1)
      expect(lessons.last).to include(lesson_name: 'Sorting', standing: :above)
      expect(lessons.first[:delta]).to be < lessons.last[:delta]
    end

    it 'buckets questions with no lesson under a labelled fallback' do
      student_stat(create(:question, topic: topic_b, lesson: nil), asked: 4, score: 2.0)

      networks = report.topic_gap_grid.find { |row| row[:topic_name] == 'Networks' }
      expect(networks[:lessons].pluck(:lesson_name)).to include('No lesson set')
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

    it 'carries the actual question stem so teachers see the specific questions' do
      expect(report.strengths.first[:question_text]).to eq(hard_aced.question_text.to_plain_text)
    end
  end

  describe 'with no data' do
    it 'returns empty sections when the student has no statistics' do
      expect(report.topic_gap_grid).to eq([])
      expect(report.strengths).to eq([])
      expect(report.cohort_comparison[:overall][:standing]).to eq(:unknown)
    end
  end
end
