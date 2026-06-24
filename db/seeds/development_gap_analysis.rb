# frozen_string_literal: true

# Seeds a deliberately-shaped scenario for the teacher gap-analysis surface (classrooms#gaps).
# The reports read the durable per-student rollup (student_question_statistics) and a global cohort
# baseline (question_statistics); neither is exercised by the other dev seeds, so without this the
# gap analysis renders empty. Development / SEED_TEST_USERS only, and idempotent: it wipes its own
# previous output (demo questions by sentinel external_id, plus every showcase class's rollups) and
# rebuilds, so re-running — even after the topic set changes — never duplicates or leaves stragglers.
#
# The three Year 11 GCSE Computer Science (OCR J277) classes share ONE demo question set so the
# cohort baseline is comparable across them:
#   * 11B Computer Science (development-11b) — mixed tier, carries the named archetypes:
#       Ada Lovelace (high), Charlie Brown (low), Beth Jones (mixed; fails Networks & Data).
#   * 11A Computer Science (development-11a) — higher-performing whole class (above cohort).
#   * 11C Computer Science (development-11c) — lower-performing whole class (below cohort).
# (Year 7 is now KS3 Computing — a separate subject/curriculum — so it no longer joins this demo.)
# Demo questions span all six question types and are split across each topic's two seeded lessons,
# with a per-lesson offset, so the heatmap drills from topic down to a real per-lesson story. One
# pupil per archetype class (Sam Carter) is enrolled but inactive so engagement shows a gap.
unless Rails.env.development? || ENV['SEED_TEST_USERS'] == 'true'
  raise "Gap-analysis seeds can only be loaded in development or with SEED_TEST_USERS=true, not #{Rails.env}."
end

require 'zlib'

# Deterministic so re-seeding produces the same (sensible) numbers.
GAP_RNG = Random.new(20_260_623)

# Six questions per topic with a fixed cohort mean score (its "ease"): two easy, two medium, two
# hard. Drives both the difficulty bands and the cohort baseline every comparison is judged against.
GAP_QUESTION_EASE = [0.86, 0.80, 0.56, 0.50, 0.28, 0.22].freeze
# One question type per ease tier, so every topic exercises all six formats and the report's
# question-type column (and the hardest-questions list) reads realistically.
GAP_QUESTION_TYPES = %w[multiple short_answer drag_drop fill_blank matrix ordering].freeze
# Placeholder topics the bare dev seed creates, and utility/import-artefact topics — skipped when the
# subject has a real imported curriculum so the heatmap shows the actual specification, not noise.
GAP_PLACEHOLDER_TOPICS = %w[Algorithms Networks Programming Data].freeze
GAP_UTILITY_TOPICS = ['Question Tester', 'Question Lucky Dip'].freeze
# Reserved external_id range so demo questions never collide with real/imported ones.
GAP_EID_BASE = 970_000
GAP_EID_SPAN = 100_000
# Whole-class ability shift per showcase tier, so the three Year 11 classes read clearly apart.
GAP_TIER_OFFSET = { high: 0.15, mixed: 0.0, baseline: 0.0, low: -0.18 }.freeze
# A pool of believable names for the high/low classes' rosters (uniqueness is by upi, so names may
# recur across classes — different pupils, same name, as in a real school).
GAP_FILLER_NAMES = [
  %w[Oliver Smith], %w[Amelia Jones], %w[Harry Taylor], %w[Isla Brown],
  %w[George Wilson], %w[Ava Davies], %w[Noah Evans], %w[Mia Thomas],
  %w[Leo Roberts], %w[Grace Walker], %w[Jack White], %w[Freya Hughes]
].freeze

# Real curriculum topics if the subject was imported, otherwise the bare placeholders. Sorted for a
# stable external_id assignment and struggle-topic pick.
def gap_topics_for(subject)
  active = subject.topics.where(active: true)
  curriculum = active.where.not(name: GAP_PLACEHOLDER_TOPICS + GAP_UTILITY_TOPICS)
  (curriculum.exists? ? curriculum : active.where(name: GAP_PLACEHOLDER_TOPICS)).order(:name).to_a
end

# The two topics our "mixed" archetype falls apart on: a networking and a data topic if present.
def gap_struggle_topics(topics)
  picks = [topics.find { |t| t.name.match?(/network/i) }, topics.find { |t| t.name.match?(/data/i) }]
  picks.compact.uniq.presence || topics.first(2)
end

# How the class as a whole fares on a topic (-0.20..+0.20), stable per topic name. Gives the heatmap
# a real gradient instead of every topic hovering around the same mean.
def gap_topic_climate(topic)
  (((Zlib.crc32(topic.name) % 1000) / 1000.0) * 0.40) - 0.20
end

# Per-topic, one lesson reads clearly weaker than the other so the lesson drill-down is not flat.
# The weak lesson alternates by topic name so it isn't always "lesson 2". The offset is applied to
# student scores but NOT the cohort baseline, so the weak lesson lands below cohort and the other
# above. `question_index` 0..2 → first lesson, 3..5 → second lesson (see gap_lesson_for).
def gap_lesson_offset(topic, question_index)
  lesson_index = question_index < (GAP_QUESTION_EASE.size / 2) ? 0 : 1
  weak_lesson = Zlib.crc32(topic.name).even? ? 0 : 1
  lesson_index == weak_lesson ? -0.12 : 0.08
end

# --- Reset previous output -----------------------------------------------------------------------

def gap_reset!(classrooms)
  demo_ids = Question.where(external_id: GAP_EID_BASE...(GAP_EID_BASE + GAP_EID_SPAN)).pluck(:id)
  StudentQuestionStatistic.where(question_id: demo_ids).delete_all
  QuestionStatistic.where(question_id: demo_ids).delete_all
  Question.where(id: demo_ids).destroy_all

  student_ids = User.where(role: 'student').joins(:enrollments)
                    .where(enrollments: { classroom_id: classrooms.map(&:id) }).select(:id)
  UsageStatistic.where(user_id: student_ids).delete_all
end

# --- Questions + cohort baseline -----------------------------------------------------------------

def gap_demo_questions(topic, topic_index)
  lessons = topic.lessons.order(:id).to_a
  GAP_QUESTION_EASE.each_with_index.map do |ease, question_index|
    external_id = GAP_EID_BASE + (topic_index * 10) + question_index
    lesson = gap_lesson_for(lessons, question_index)
    question = gap_create_question(topic, external_id, question_index, topic_index, lesson)
    gap_create_question_statistic(question, ease)
    [question, ease]
  end
end

# Split the six ease tiers across the topic's two seeded lessons (easier half → lesson one), so the
# lesson breakdown carries real, differently-shaped lessons. Falls back to no lesson if a topic has
# none (the breakdown then buckets under "No lesson set").
def gap_lesson_for(lessons, question_index)
  return nil if lessons.empty?

  lessons[question_index < (GAP_QUESTION_EASE.size / 2) ? 0 : 1] || lessons.first
end

# Each topic carries all six types, but the type→ease mapping is rotated per topic so the hardest
# questions across the subject span every format (otherwise one type would always top the list).
def gap_create_question(topic, external_id, question_index, topic_index, lesson)
  question_type = GAP_QUESTION_TYPES[(question_index + topic_index) % GAP_QUESTION_TYPES.size]
  Question.create!(
    external_id:, topic:, lesson:, question_type:,
    **gap_question_content(question_type, topic, question_index)
  )
end

# Minimal-but-valid content per type: answer rows for the answer-based types, and a config that
# satisfies StructuredQuestion's validations for the cloze / grid / ordering types.
def gap_question_content(question_type, topic, question_index)
  label = "[#{topic.name}] Sample question #{question_index + 1}"
  case question_type
  when 'short_answer', 'multiple'
    { question_text: label, answers_attributes: gap_answers_for(question_type) }
  when 'drag_drop' then gap_drag_drop_content(topic)
  when 'fill_blank' then gap_fill_blank_content(topic)
  when 'matrix' then gap_matrix_content(topic)
  when 'ordering' then gap_ordering_content(topic)
  end
end

def gap_answers_for(question_type)
  return [{ text: 'Correct answer', correct: true }] if question_type == 'short_answer'

  [{ text: 'Correct answer', correct: true },
   { text: 'Distractor A', correct: false },
   { text: 'Distractor B', correct: false }]
end

def gap_drag_drop_content(topic)
  { question_text: "[#{topic.name}] Drag the terms: the {{1}} unit and the {{2}} unit.",
    config: { 'items' => [{ 'id' => 'i1', 'text' => 'first' }, { 'id' => 'i2', 'text' => 'second' },
                          { 'id' => 'i3', 'text' => 'distractor' }],
              'answer' => { '1' => 'i1', '2' => 'i2' } } }
end

def gap_fill_blank_content(topic)
  { question_text: "[#{topic.name}] Type the missing term: data is held in {{1}}.",
    config: { 'answer' => { '1' => 'memory|RAM' } } }
end

def gap_matrix_content(topic)
  { question_text: "[#{topic.name}] Tick the correct classification for each item.",
    config: { 'rows' => [{ 'id' => 'r1', 'label' => 'Item A' }, { 'id' => 'r2', 'label' => 'Item B' }],
              'columns' => [{ 'id' => 'c1', 'label' => 'Category 1' }, { 'id' => 'c2', 'label' => 'Category 2' }],
              'correct' => { 'r1' => ['c1'], 'r2' => ['c2'] } } }
end

def gap_ordering_content(topic)
  { question_text: "[#{topic.name}] Put the steps in the correct order.",
    config: { 'items' => [{ 'id' => 's1', 'text' => 'First step' }, { 'id' => 's2', 'text' => 'Second step' },
                          { 'id' => 's3', 'text' => 'Third step' }],
              'order' => %w[s1 s2 s3] } }
end

# Heavily sampled so the difficulty engine trusts the empirical mean and the band lands as intended.
def gap_create_question_statistic(question, ease)
  asked = 300
  QuestionStatistic.create!(question:, number_asked: asked,
                            score_sum: (asked * ease).round.to_f, number_correct: (asked * ease).round)
end

# --- Students ------------------------------------------------------------------------------------

def gap_upsert_student(school, classroom, key, forename, surname)
  student = upsert_user(school:, username: "gap-#{key}", forename:, surname:,
                        role: 'student', upi: "development-gap-#{key}")
  enroll(user: student, classroom:)
  student
end

# The named-archetype roster (used by 7c and 11b). `suffix` keeps each class's pupils distinct so a
# re-used name never collides on upi; the original 7c roster passes "" to stay byte-for-byte stable.
def gap_archetype_roster(school, classroom, suffix)
  [
    [gap_upsert_student(school, classroom, "ada#{suffix}", 'Ada', 'Lovelace'), :high],
    [gap_upsert_student(school, classroom, "charlie#{suffix}", 'Charlie', 'Brown'), :low],
    [gap_upsert_student(school, classroom, "beth#{suffix}", 'Beth', 'Jones'), :struggling],
    [gap_upsert_student(school, classroom, "dev#{suffix}", 'Dev', 'Patel'), :filler],
    [gap_upsert_student(school, classroom, "ellie#{suffix}", 'Ellie', 'Wong'), :filler],
    [gap_upsert_student(school, classroom, "mia#{suffix}", 'Mia', 'Khan'), :filler],
    [gap_upsert_student(school, classroom, "tom#{suffix}", 'Tom', 'Reed'), :filler],
    [gap_upsert_student(school, classroom, "sam#{suffix}", 'Sam', 'Carter'), :inactive]
  ]
end

# A roster of believable, all-filler pupils for the tier-shifted high / low classes.
def gap_named_filler_roster(school, classroom, suffix)
  GAP_FILLER_NAMES.first(10).each_with_index.map do |(forename, surname), index|
    [gap_upsert_student(school, classroom, "#{suffix}-#{index}", forename, surname), :filler]
  end
end

# Per-topic ability (0..1): archetypes are deliberate, fillers spread around the cohort, and every
# pupil is nudged by the topic's class climate so the heatmap varies topic to topic.
def gap_ability(student, profile, topic, struggle_ids)
  climate = gap_topic_climate(topic)
  case profile
  when :high then (0.95 + (climate * 0.3)).clamp(0.0, 1.0)
  when :low then (0.24 + (climate * 0.3)).clamp(0.0, 1.0)
  when :struggling then gap_struggling_ability(topic, climate, struggle_ids)
  else (gap_filler_base(student) + climate + (GAP_RNG.rand * 0.08) - 0.04).clamp(0.0, 1.0)
  end
end

def gap_struggling_ability(topic, climate, struggle_ids)
  return (0.24 + (climate * 0.2)).clamp(0.0, 1.0) if struggle_ids.include?(topic.id)

  # Squarely mid-table on everything else, so overall she reads "on par" and the two weak topics —
  # not a low headline number — are what stands out.
  (0.52 + (climate * 0.5)).clamp(0.0, 1.0)
end

def gap_filler_base(student)
  0.32 + ((student.id % 7) / 7.0 * 0.46) # ~0.32..0.78, stable per pupil
end

# A pupil's expected mean score on a question: ability nudged by how easy the item is, by the
# per-lesson offset, plus noise.
def gap_expected_score(ability, ease, lesson_offset)
  (ability + ((ease - 0.5) * 0.5) + lesson_offset + (GAP_RNG.rand * 0.08) - 0.04).clamp(0.0, 1.0)
end

def gap_seed_student(student, profile, tier, demo_by_topic, struggle_ids)
  tier_offset = GAP_TIER_OFFSET.fetch(tier, 0.0)
  demo_by_topic.each do |topic, questions|
    ability = (gap_ability(student, profile, topic, struggle_ids) + tier_offset).clamp(0.0, 1.0)
    questions.each_with_index do |(question, ease), index|
      gap_create_rollup(student, question, gap_expected_score(ability, ease, gap_lesson_offset(topic, index)))
    end
    gap_create_usage(student, topic, profile) unless profile == :inactive
  end
end

def gap_create_rollup(student, question, expected)
  asked = GAP_RNG.rand(4..10)
  score = (asked * expected).round(1)
  StudentQuestionStatistic.create!(user: student, question:, number_asked: asked, score_sum: score,
                                   number_correct: score.round, last_asked_at: GAP_RNG.rand(1..21).days.ago)
end

def gap_create_usage(student, topic, profile)
  quizzes = profile == :low ? GAP_RNG.rand(1..3) : GAP_RNG.rand(3..10)
  UsageStatistic.create!(user: student, topic:, quizzes_started: quizzes,
                         questions_answered: quizzes * GAP_RNG.rand(6..10), date: GAP_RNG.rand(1..21).days.ago)
end

# Seed one class: build its roster (per its tier/style), give every pupil rollups against the shared
# demo questions, then top up any other already-enrolled pupils as cohort-average fillers.
def gap_seed_classroom(classroom, tier, demo_by_topic, struggle_ids, roster)
  roster.each { |student, profile| gap_seed_student(student, profile, tier, demo_by_topic, struggle_ids) }

  seeded_ids = roster.map { |student, _| student.id }
  classroom.users.where(role: 'student').where.not(id: seeded_ids).find_each do |student|
    gap_seed_student(student, :filler, tier, demo_by_topic, struggle_ids)
  end
end

# --- Build the scenario --------------------------------------------------------------------------

def gap_showcase_classes
  [
    { classroom: Classroom.find_by(client_id: 'development-11b'), tier: :mixed, roster: :archetype, suffix: '-11b' },
    { classroom: Classroom.find_by(client_id: 'development-11a'), tier: :high, roster: :filler, suffix: '11a' },
    { classroom: Classroom.find_by(client_id: 'development-11c'), tier: :low, roster: :filler, suffix: '11c' }
  ].select { |row| row[:classroom]&.subject }
end

def gap_roster_for(row)
  classroom = row[:classroom]
  school = classroom.school
  if row[:roster] == :archetype
    gap_archetype_roster(school, classroom, row[:suffix])
  else
    gap_named_filler_roster(school, classroom, row[:suffix])
  end
end

showcase = gap_showcase_classes

if showcase.empty?
  Rails.logger.info('Gap-analysis seed skipped: no showcase classrooms (development-11a / -11b / -11c) found.')
else
  gap_reset!(showcase.map { |row| row[:classroom] })

  # All showcase classes share one Computer Science demo question set so the cohort baseline lines up.
  subject = showcase.first[:classroom].subject
  topics = gap_topics_for(subject)
  demo_by_topic = topics.each_with_index.to_h { |topic, index| [topic, gap_demo_questions(topic, index)] }
  struggle_ids = gap_struggle_topics(topics).map(&:id)

  showcase.each do |row|
    gap_seed_classroom(row[:classroom], row[:tier], demo_by_topic, struggle_ids, gap_roster_for(row))
  end

  struggle_names = topics.select { |t| struggle_ids.include?(t.id) }.map(&:name).join(' & ')
  puts %(Gap-analysis showcase seeded across #{topics.size} J277 topics, all six question types, with)
  puts '  per-lesson drill-down, for these GCSE Computer Science classes:'
  puts %(  11B Computer Science — mixed tier; Ada (high), Charlie (low), Beth (fails #{struggle_names}))
  puts '  11A Computer Science — higher-performing whole class (above cohort)'
  puts '  11C Computer Science — lower-performing whole class (below cohort)'
  puts '  Sign in as teacher1 / password → a class → View Gap Analysis (expand a topic for lessons).'
end
