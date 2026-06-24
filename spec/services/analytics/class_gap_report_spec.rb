# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Analytics::ClassGapReport do
  subject(:report) { described_class.call(classroom) }

  let(:subject_area) { create(:subject) }
  let(:classroom) { create(:classroom, subject: subject_area) }
  let(:topic_a) { create(:topic, subject: subject_area, name: 'Algorithms') }
  let(:topic_b) { create(:topic, subject: subject_area, name: 'Networks') }
  let(:alice) { create(:student, school: classroom.school) }
  let(:bob) { create(:student, school: classroom.school) }

  def enrol(user)
    Enrollment.create!(classroom: classroom, user: user)
  end

  def student_stat(user, question, asked:, score:)
    create(:student_question_statistic, user: user, question: question,
                                        number_asked: asked, number_correct: score.to_i, score_sum: score)
  end

  before do
    enrol(alice)
    enrol(bob)
  end

  describe 'topic gap grid' do
    let(:easy_q) { create(:question, topic: topic_a, question_type: 'multiple') }
    let(:hard_q) { create(:question, topic: topic_b, question_type: 'short_answer') }

    before do
      # Algorithms: 12/20 => 0.6.  Networks: 4/20 => 0.2.
      student_stat(alice, easy_q, asked: 10, score: 8.0)
      student_stat(bob, easy_q, asked: 10, score: 4.0)
      student_stat(alice, hard_q, asked: 10, score: 3.0)
      student_stat(bob, hard_q, asked: 10, score: 1.0)
      # Cohort baseline: class beats the cohort on Networks, trails it on Algorithms.
      create(:question_statistic, question: easy_q, number_asked: 100, number_correct: 90, score_sum: 90.0)
      create(:question_statistic, question: hard_q, number_asked: 100, number_correct: 5, score_sum: 5.0)
    end

    it 'orders topics most below the cohort first, carrying standing and attempt volume' do
      grid = report.topic_gap_grid

      # Algorithms trails the cohort (delta negative) and leads; Networks beats it.
      expect(grid.pluck(:topic_name)).to eq(%w[Algorithms Networks])
      expect(grid.first).to include(topic_name: 'Algorithms', standing: :below)
      expect(grid.last).to include(topic_name: 'Networks', standing: :above, attempts: 20, students: 2)
      expect(grid.first[:delta]).to be < grid.last[:delta]
    end

    it 'sinks topics with no cohort comparison to the bottom' do
      topic_c = create(:topic, subject: subject_area, name: 'Databases')
      lonely = create(:question, topic: topic_c, question_type: 'multiple')
      student_stat(alice, lonely, asked: 5, score: 2.0) # no question_statistic => unknown standing

      expect(report.topic_gap_grid.last).to include(topic_name: 'Databases', standing: :unknown)
    end
  end

  describe 'lesson drill-down within a topic' do
    let(:lesson_x) { create(:lesson, topic: topic_a, title: 'Big O') }
    let(:lesson_y) { create(:lesson, topic: topic_a, title: 'Sorting') }
    let(:q_x) { create(:question, topic: topic_a, lesson: lesson_x, question_type: 'multiple') }
    let(:q_y) { create(:question, topic: topic_a, lesson: lesson_y, question_type: 'multiple') }
    let(:q_none) { create(:question, topic: topic_a, lesson: nil, question_type: 'multiple') }

    before do
      # Big O: class 0.8 vs cohort 0.2 (well above). Sorting: class 0.2 vs cohort 0.8 (well below).
      # q_none has no cohort baseline, so its standing is unknown and it sinks to the bottom.
      student_stat(alice, q_x, asked: 10, score: 8.0)
      student_stat(alice, q_y, asked: 10, score: 2.0)
      student_stat(alice, q_none, asked: 4, score: 2.0)
      create(:question_statistic, question: q_x, number_asked: 100, number_correct: 20, score_sum: 20.0)
      create(:question_statistic, question: q_y, number_asked: 100, number_correct: 80, score_sum: 80.0)
    end

    def algorithms_lessons
      report.topic_gap_grid.find { |row| row[:topic_name] == 'Algorithms' }[:lessons]
    end

    it 'breaks a topic cell down by lesson, weakest first, with cohort-relative standing' do
      lessons = algorithms_lessons

      expect(lessons.pluck(:lesson_name)).to eq(['Sorting', 'Big O', 'No lesson set'])
      expect(lessons.first).to include(lesson_name: 'Sorting', standing: :below, attempts: 10, questions: 1)
      expect(lessons.find { |l| l[:lesson_name] == 'Big O' }).to include(standing: :above)
      expect(lessons.first[:delta]).to be < lessons.find { |l| l[:lesson_name] == 'Big O' }[:delta]
    end

    it 'buckets questions with no lesson under a labelled fallback and marks them unknown' do
      expect(algorithms_lessons.last).to include(lesson_name: 'No lesson set', standing: :unknown, questions: 1)
    end
  end

  describe 'hardest questions' do
    let(:gentle) { create(:question, topic: topic_a, question_type: 'multiple') }
    let(:brutal) { create(:short_answer_question, topic: topic_b) }

    before do
      student_stat(alice, gentle, asked: 10, score: 9.0)
      student_stat(alice, brutal, asked: 10, score: 1.0)
      # Cohort-wide stats drive the difficulty engine: brutal is hard, gentle is easy.
      create(:question_statistic, question: gentle, number_asked: 1000, number_correct: 900, score_sum: 900.0)
      create(:question_statistic, question: brutal, number_asked: 1000, number_correct: 100, score_sum: 100.0)
    end

    it 'ranks by cohort difficulty, hardest first, with band, the question text and class mean' do
      hardest = report.hardest_questions

      expect(hardest.first).to include(question_id: brutal.id, band: :hard,
                                       question_text: brutal.question_text.to_plain_text,
                                       class_mean_score: 0.1)
      expect(hardest.first[:difficulty]).to be > hardest.last[:difficulty]
      expect(hardest.last).to include(question_id: gentle.id, band: :easy)
    end

    it 'caps the list at HARDEST_QUESTIONS_LIMIT' do
      create_list(:question, described_class::HARDEST_QUESTIONS_LIMIT + 3, topic: topic_a).each do |q|
        student_stat(alice, q, asked: 5, score: 2.0)
      end

      expect(report.hardest_questions.size).to eq(described_class::HARDEST_QUESTIONS_LIMIT)
    end
  end

  describe 'cohort comparison' do
    let(:question) { create(:short_answer_question, topic: topic_a) }

    before do
      # Class averages 0.6 on an item the wider cohort only manages 0.1 on => well above cohort.
      student_stat(alice, question, asked: 10, score: 6.0)
      student_stat(bob, question, asked: 10, score: 6.0)
      create(:question_statistic, question: question, number_asked: 1000, number_correct: 100, score_sum: 100.0)
    end

    it 'reports difficulty-weighted mastery above the global cohort' do
      overall = report.cohort_comparison[:overall]

      expect(overall[:mastery]).to be_within(0.01).of(0.6)
      expect(overall[:cohort_mastery]).to be_within(0.01).of(0.1)
      expect(overall[:delta]).to be > 0
      expect(overall[:standing]).to eq(:above)
    end

    it 'breaks the comparison down per topic' do
      by_topic = report.cohort_comparison[:by_topic]

      expect(by_topic.pluck(:topic_name)).to include('Algorithms')
      expect(by_topic.first).to include(:mastery, :cohort_mastery, :delta, :standing, :topic_id, :topic_name)
    end
  end

  describe 'engagement' do
    let(:question) { create(:question, topic: topic_a) }

    before do
      # Answered counts come from the durable per-question rollup; quizzes-started from usage stats.
      student_stat(alice, question, asked: 25, score: 20.0)
      student_stat(bob, question, asked: 8, score: 4.0)
      create(:usage_statistic, user: alice, topic: topic_a, quizzes_started: 3)
      create(:usage_statistic, user: bob, topic: topic_a, quizzes_started: 1)
    end

    it 'counts answered questions from the rollup and quizzes from usage statistics' do
      engagement = report.engagement

      expect(engagement[:students_active]).to eq(2)
      expect(engagement[:quizzes_started]).to eq(4)
      expect(engagement[:questions_answered]).to eq(33)
      expect(engagement[:per_student].first[:name]).to eq("#{alice.forename} #{alice.surname}")
    end

    it 'counts a student who has started a quiz but not yet had answers rolled up as active' do
      create(:usage_statistic, user: create(:student, school: classroom.school).tap { |s| enrol(s) },
                               topic: topic_a, quizzes_started: 2)

      expect(report.engagement[:students_active]).to eq(3)
    end
  end

  describe 'with no data' do
    it 'returns empty sections for an empty classroom' do
      empty = described_class.call(create(:classroom, subject: subject_area))

      expect(empty.student_count).to eq(0)
      expect(empty.topic_gap_grid).to eq([])
      expect(empty.hardest_questions).to eq([])
      expect(empty.cohort_comparison[:overall][:standing]).to eq(:unknown)
      expect(empty.engagement[:students_active]).to eq(0)
    end

    it 'handles a classroom with no subject' do
      no_subject = described_class.call(create(:classroom, subject: nil))

      expect(no_subject.topic_gap_grid).to eq([])
    end
  end

  describe 'query efficiency' do
    let(:question) { create(:question, topic: topic_a) }

    before do
      student_stat(alice, question, asked: 5, score: 3.0)
      student_stat(bob, question, asked: 5, score: 2.0)
    end

    it 'never issues a query per student (no N+1)' do
      create_list(:student, 5, school: classroom.school).each do |s|
        enrol(s)
        student_stat(s, question, asked: 4, score: 2.0)
      end

      queries = 0
      counter = ->(_n, _s, _f, _i, _payload) { queries += 1 }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        report = described_class.call(classroom)
        report.topic_gap_grid
        report.hardest_questions
        report.cohort_comparison
        report.engagement
      end

      # A small, student-count-independent number of aggregate queries.
      expect(queries).to be < 25
    end
  end
end
