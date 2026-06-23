# frozen_string_literal: true

# Seeds a deliberately-shaped scenario for the teacher gap-analysis surface (classrooms#gaps).
# The reports read the durable per-student rollup (student_question_statistics) and a global cohort
# baseline (question_statistics); neither is exercised by the other dev seeds, so without this the
# gap analysis renders empty. Development / SEED_TEST_USERS only, and idempotent: it wipes its own
# previous output (demo questions by sentinel external_id, plus the showcase class's rollups) and
# rebuilds, so re-running — even after the topic set changes — never duplicates or leaves stragglers.
#
# The scenario is built around three legible archetypes in "7 Computer Science" so the surface tells
# a clear story rather than showing random noise:
#   * Ada Lovelace  — high ability: above the cohort in every topic, aces the hardest questions.
#   * Charlie Brown — low ability:  below the cohort, a long list of priority gaps on the basics.
#   * Beth Jones    — mixed:        solid overall but clearly failing two topics (Networks, Data).
# The rest of the class spreads across the cohort average, and each topic carries a "climate" offset
# so the class heatmap shows a genuine weak→strong gradient across every topic in the subject. One
# pupil (Sam Carter) is enrolled but inactive so the engagement section shows a participation gap.
unless Rails.env.development? || ENV['SEED_TEST_USERS'] == 'true'
  raise "Gap-analysis seeds can only be loaded in development or with SEED_TEST_USERS=true, not #{Rails.env}."
end

require 'zlib'

# Deterministic so re-seeding produces the same (sensible) numbers.
GAP_RNG = Random.new(20_260_623)

# Six questions per topic with a fixed cohort mean score (its "ease"): two easy, two medium, two
# hard. Drives both the difficulty bands and the cohort baseline every comparison is judged against.
GAP_QUESTION_EASE = [0.86, 0.80, 0.56, 0.50, 0.28, 0.22].freeze
# Placeholder topics the bare dev seed creates, and utility/import-artefact topics — skipped when the
# subject has a real imported curriculum so the heatmap shows the actual specification, not noise.
GAP_PLACEHOLDER_TOPICS = %w[Algorithms Networks Programming Data].freeze
GAP_UTILITY_TOPICS = ['Question Tester', 'Question Lucky Dip'].freeze
# Reserved external_id range so demo questions never collide with real/imported ones.
GAP_EID_BASE = 970_000
GAP_EID_SPAN = 100_000

def gap_showcase_classroom
  Classroom.find_by(client_id: 'development-7c')
end

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

# --- Reset previous output -----------------------------------------------------------------------

def gap_reset!(classroom)
  demo_ids = Question.where(external_id: GAP_EID_BASE...(GAP_EID_BASE + GAP_EID_SPAN)).pluck(:id)
  StudentQuestionStatistic.where(question_id: demo_ids).delete_all
  QuestionStatistic.where(question_id: demo_ids).delete_all
  Question.where(id: demo_ids).destroy_all
  UsageStatistic.where(user_id: classroom.users.where(role: 'student').select(:id)).delete_all
end

# --- Questions + cohort baseline -----------------------------------------------------------------

def gap_demo_questions(topic, topic_index)
  GAP_QUESTION_EASE.each_with_index.map do |ease, question_index|
    question = gap_create_question(topic, GAP_EID_BASE + (topic_index * 10) + question_index, question_index)
    gap_create_question_statistic(question, ease)
    [question, ease]
  end
end

def gap_create_question(topic, external_id, question_index)
  question_type = question_index.even? ? 'multiple' : 'short_answer'
  Question.create!(
    external_id:, topic:, question_type:,
    question_text: "[#{topic.name}] Sample question #{question_index + 1}",
    answers_attributes: gap_answers_for(question_type)
  )
end

def gap_answers_for(question_type)
  return [{ text: 'Correct answer', correct: true }] if question_type == 'short_answer'

  [{ text: 'Correct answer', correct: true },
   { text: 'Distractor A', correct: false },
   { text: 'Distractor B', correct: false }]
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

# A pupil's expected mean score on a question: ability nudged by how easy the item is, plus noise.
def gap_expected_score(ability, ease)
  (ability + ((ease - 0.5) * 0.5) + (GAP_RNG.rand * 0.08) - 0.04).clamp(0.0, 1.0)
end

def gap_seed_student(student, profile, demo_by_topic, struggle_ids)
  demo_by_topic.each do |topic, questions|
    ability = gap_ability(student, profile, topic, struggle_ids)
    questions.each { |question, ease| gap_create_rollup(student, question, gap_expected_score(ability, ease)) }
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

# --- Build the scenario --------------------------------------------------------------------------

classroom = gap_showcase_classroom

if classroom.nil? || classroom.subject.nil?
  Rails.logger.info('Gap-analysis seed skipped: showcase classroom "development-7c" not found.')
else
  gap_reset!(classroom)

  school = classroom.school
  topics = gap_topics_for(classroom.subject)
  demo_by_topic = topics.each_with_index.to_h { |topic, index| [topic, gap_demo_questions(topic, index)] }
  struggle_ids = gap_struggle_topics(topics).map(&:id)

  archetypes = [
    [gap_upsert_student(school, classroom, 'ada', 'Ada', 'Lovelace'), :high],
    [gap_upsert_student(school, classroom, 'charlie', 'Charlie', 'Brown'), :low],
    [gap_upsert_student(school, classroom, 'beth', 'Beth', 'Jones'), :struggling]
  ]

  fillers = [
    [gap_upsert_student(school, classroom, 'dev', 'Dev', 'Patel'), :filler],
    [gap_upsert_student(school, classroom, 'ellie', 'Ellie', 'Wong'), :filler],
    [gap_upsert_student(school, classroom, 'mia', 'Mia', 'Khan'), :filler],
    [gap_upsert_student(school, classroom, 'tom', 'Tom', 'Reed'), :filler],
    [gap_upsert_student(school, classroom, 'sam', 'Sam', 'Carter'), :inactive]
  ]

  (archetypes + fillers).each { |student, profile| gap_seed_student(student, profile, demo_by_topic, struggle_ids) }

  # Give every other already-enrolled pupil cohort-average data so the class is fully populated.
  seeded_ids = (archetypes + fillers).map { |student, _| student.id }
  classroom.users.where(role: 'student').where.not(id: seeded_ids).find_each do |student|
    gap_seed_student(student, :filler, demo_by_topic, struggle_ids)
  end

  struggle_names = topics.select { |t| struggle_ids.include?(t.id) }.map(&:name).join(' & ')
  puts %(Gap-analysis showcase seeded for "7 Computer Science" across #{topics.size} topics:)
  puts '  Ada Lovelace   — high ability  (above cohort everywhere; aces the hardest questions)'
  puts '  Charlie Brown  — low ability   (below cohort; many priority gaps on the basics)'
  puts %(  Beth Jones     — mixed         (around the class average, but clearly failing #{struggle_names}))
  puts '  + classmates spread around the cohort; Sam Carter is enrolled but inactive.'
  puts '  Sign in as teacher1 / password → "7 Computer Science" → View Gap Analysis.'
end
