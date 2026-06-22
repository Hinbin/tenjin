# frozen_string_literal: true

# A dedicated "Question Tester" topic under Computer Science that showcases every question type —
# especially the newer structured ones (fill_blank, ordering) alongside drag_drop, matrix and the
# classic answer-based types. Handy for manually exercising the quiz UI locally.
#
# Idempotent: the subject/topic are found-or-created and the questions are only seeded when the topic
# has none yet, so re-running the seeds never duplicates them. Loadable standalone with:
#   bin/rails runner 'load Rails.root.join("db/seeds/question_tester.rb")'

def seed_question_tester
  subject = Subject.find_or_create_by!(name: 'Computer Science')
  topic = Topic.find_or_create_by!(subject:, name: 'Question Tester')

  if topic.questions.exists?
    Rails.logger.info('Question Tester topic already seeded; skipping.')
    return
  end

  seed_question_tester_structured(topic)
  seed_question_tester_basics(topic)
  Rails.logger.info('Seeded Question Tester topic.')
end

def seed_question_tester_structured(topic)
  Question.create!(
    topic:, question_type: 'fill_blank',
    question_text: 'A loop that repeats a fixed number of times is called a {{1}} loop.',
    config: { 'answer' => { '1' => 'count-controlled|count controlled' } },
    explanation: 'A count-controlled loop runs a set number of times (e.g. FOR i = 1 TO 10). ' \
                 'Compare it with a condition-controlled loop, which repeats until a condition changes.'
  )

  Question.create!(
    topic:, question_type: 'fill_blank',
    question_text: 'In binary the smallest unit of data is a {{1}}, and eight of them make one {{2}}.',
    config: { 'answer' => { '1' => 'bit', '2' => 'byte' } },
    explanation: 'A bit is a single 0 or 1. Eight bits group together to form one byte, ' \
                 'which can represent 256 different values (2^8).'
  )

  Question.create!(
    topic:, question_type: 'ordering',
    question_text: 'Put the stages of the fetch–decode–execute cycle into the correct order.',
    config: {
      'items' => [{ 'id' => 'o1', 'text' => 'Fetch the instruction from memory' },
                  { 'id' => 'o2', 'text' => 'Decode the instruction' },
                  { 'id' => 'o3', 'text' => 'Execute the instruction' }],
      'order' => %w[o1 o2 o3]
    },
    explanation: 'The CPU first fetches the next instruction from memory, decodes it to work out ' \
                 'what is required, then executes it. This cycle repeats for every instruction.'
  )

  Question.create!(
    topic:, question_type: 'ordering',
    question_text: 'Order these units of storage from smallest to largest.',
    config: {
      'items' => [{ 'id' => 'u1', 'text' => 'Bit' }, { 'id' => 'u2', 'text' => 'Nibble' },
                  { 'id' => 'u3', 'text' => 'Byte' }, { 'id' => 'u4', 'text' => 'Kilobyte' },
                  { 'id' => 'u5', 'text' => 'Megabyte' }],
      'order' => %w[u1 u2 u3 u4 u5]
    }
  )

  Question.create!(
    topic:, question_type: 'drag_drop',
    question_text: 'The CPU contains the {{1}} unit and the {{2}} unit.',
    config: {
      'items' => [{ 'id' => 'i1', 'text' => 'control' }, { 'id' => 'i2', 'text' => 'arithmetic logic' },
                  { 'id' => 'i3', 'text' => 'storage (distractor)' }],
      'answer' => { '1' => 'i1', '2' => 'i2' }
    },
    explanation: 'The control unit (CU) directs the operation of the processor, while the ' \
                 'arithmetic logic unit (ALU) carries out calculations and logical comparisons.'
  )

  Question.create!(
    topic:, question_type: 'matrix',
    question_text: 'Tick the correct classification for each language.',
    config: {
      'rows' => [{ 'id' => 'r1', 'label' => 'Python' }, { 'id' => 'r2', 'label' => 'HTML' },
                 { 'id' => 'r3', 'label' => 'C++' }],
      'columns' => [{ 'id' => 'c1', 'label' => 'Interpreted' }, { 'id' => 'c2', 'label' => 'Compiled' },
                    { 'id' => 'c3', 'label' => 'Markup' }],
      'correct' => { 'r1' => ['c1'], 'r2' => ['c3'], 'r3' => ['c2'] }
    }
  )
end

def seed_question_tester_basics(topic)
  Question.create!(
    topic:, question_type: 'multiple',
    question_text: 'What is the denary (decimal) value of the binary number 1010?',
    answers_attributes: [{ text: '10', correct: true }, { text: '12', correct: false },
                         { text: '8', correct: false }, { text: '5', correct: false }],
    explanation: '1010 in binary = (8×1)+(4×0)+(2×1)+(1×0) = 8 + 2 = 10.'
  )

  Question.create!(
    topic:, question_type: 'short_answer',
    question_text: "What does the acronym 'CPU' stand for?",
    answers_attributes: [{ text: 'Central Processing Unit', correct: true }],
    explanation: 'The CPU (Central Processing Unit) is the part of the computer that fetches, ' \
                 'decodes and executes instructions — often called the “brain” of the computer.'
  )

  Question.create!(
    topic:, question_type: 'multiple',
    question_text: 'True or False: a compiler translates the entire program before it runs.',
    answers_attributes: [{ text: 'True', correct: true }, { text: 'False', correct: false }]
  )
end

seed_question_tester
