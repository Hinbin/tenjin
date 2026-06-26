# frozen_string_literal: true

# A dedicated "Question Tester" topic under Computer Science that showcases every question type —
# especially the newer structured ones (fill_blank, ordering, classify) alongside drag_drop, matrix
# and the classic answer-based types. Handy for manually exercising the quiz UI locally.
#
# Idempotent per question type: each seeder checks whether questions of that type already exist
# before inserting, so re-running never duplicates. Loadable standalone with:
#   bin/rails runner 'load Rails.root.join("db/seeds/question_tester.rb")'

def seed_question_tester
  subject = Subject.find_or_create_by!(name: 'Computer Science')
  topic = Topic.find_or_create_by!(subject:, name: 'Question Tester')

  unless topic.questions.where(question_type: %w[fill_blank ordering drag_drop matrix multiple short_answer]).exists?
    seed_question_tester_structured(topic)
    seed_question_tester_basics(topic)
    Rails.logger.info('Seeded Question Tester topic (structured + basic).')
  end

  unless topic.questions.classify.exists?
    seed_question_tester_classify(topic)
    Rails.logger.info('Seeded Question Tester topic (classify).')
  end
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
                 'decodes and executes instructions — often called the "brain" of the computer.'
  )

  Question.create!(
    topic:, question_type: 'multiple',
    question_text: 'True or False: a compiler translates the entire program before it runs.',
    answers_attributes: [{ text: 'True', correct: true }, { text: 'False', correct: false }]
  )
end

def seed_question_tester_classify(topic)
  Question.create!(
    topic:, question_type: 'classify',
    question_text: 'Classify each item as hardware or software.',
    config: {
      'items' => [
        { 'id' => 'c1', 'text' => 'CPU' },
        { 'id' => 'c2', 'text' => 'Operating System' },
        { 'id' => 'c3', 'text' => 'RAM' },
        { 'id' => 'c4', 'text' => 'Web Browser' },
        { 'id' => 'c5', 'text' => 'Graphics Card' },
        { 'id' => 'c6', 'text' => 'Python Interpreter' }
      ],
      'targets' => [
        { 'id' => 't1', 'label' => 'Hardware' },
        { 'id' => 't2', 'label' => 'Software' }
      ],
      'correct' => { 'c1' => 't1', 'c2' => 't2', 'c3' => 't1', 'c4' => 't2', 'c5' => 't1', 'c6' => 't2' }
    },
    explanation: 'Hardware refers to the physical components of a computer system. ' \
                 'Software is a set of instructions that tells the hardware what to do.'
  )
end

def seed_classify_system_architecture
  subject = Subject.find_or_create_by!(name: 'Computer Science')
  topic = Topic.find_or_create_by!(subject:, name: '1-1 System Architecture')

  if topic.questions.classify.exists?
    Rails.logger.info('1-1 System Architecture classify questions already seeded; skipping.')
    return
  end

  Question.create!(
    topic:, question_type: 'classify',
    question_text: 'Classify each component as part of the CPU or not part of the CPU.',
    config: {
      'items' => [
        { 'id' => 'a1', 'text' => 'ALU' },
        { 'id' => 'a2', 'text' => 'RAM' },
        { 'id' => 'a3', 'text' => 'Control Unit' },
        { 'id' => 'a4', 'text' => 'Cache' },
        { 'id' => 'a5', 'text' => 'Hard Drive' },
        { 'id' => 'a6', 'text' => 'Registers' }
      ],
      'targets' => [
        { 'id' => 't1', 'label' => 'CPU Component' },
        { 'id' => 't2', 'label' => 'Not a CPU Component' }
      ],
      'correct' => { 'a1' => 't1', 'a2' => 't2', 'a3' => 't1', 'a4' => 't1', 'a5' => 't2', 'a6' => 't1' }
    },
    explanation: 'The CPU contains the ALU, Control Unit, Cache, and Registers. ' \
                 'RAM and the hard drive are separate components outside the CPU itself.'
  )

  Question.create!(
    topic:, question_type: 'classify',
    question_text: 'Classify each type of memory as volatile or non-volatile.',
    config: {
      'items' => [
        { 'id' => 'b1', 'text' => 'RAM' },
        { 'id' => 'b2', 'text' => 'ROM' },
        { 'id' => 'b3', 'text' => 'Cache' },
        { 'id' => 'b4', 'text' => 'Flash Storage' },
        { 'id' => 'b5', 'text' => 'DRAM' },
        { 'id' => 'b6', 'text' => 'BIOS Chip' }
      ],
      'targets' => [
        { 'id' => 't1', 'label' => 'Volatile' },
        { 'id' => 't2', 'label' => 'Non-volatile' }
      ],
      'correct' => { 'b1' => 't1', 'b2' => 't2', 'b3' => 't1', 'b4' => 't2', 'b5' => 't1', 'b6' => 't2' }
    },
    explanation: 'Volatile memory loses its contents when power is removed (RAM, Cache, DRAM). ' \
                 'Non-volatile memory retains data without power (ROM, Flash Storage, BIOS Chip).'
  )

  Question.create!(
    topic:, question_type: 'classify',
    question_text: 'Classify each device as an input device, output device, or storage device.',
    config: {
      'items' => [
        { 'id' => 'd1', 'text' => 'Keyboard' },
        { 'id' => 'd2', 'text' => 'Monitor' },
        { 'id' => 'd3', 'text' => 'Hard Drive' },
        { 'id' => 'd4', 'text' => 'Mouse' },
        { 'id' => 'd5', 'text' => 'Speaker' },
        { 'id' => 'd6', 'text' => 'SSD' }
      ],
      'targets' => [
        { 'id' => 't1', 'label' => 'Input' },
        { 'id' => 't2', 'label' => 'Output' },
        { 'id' => 't3', 'label' => 'Storage' }
      ],
      'correct' => { 'd1' => 't1', 'd2' => 't2', 'd3' => 't3', 'd4' => 't1', 'd5' => 't2', 'd6' => 't3' }
    },
    explanation: 'Input devices send data into the computer (keyboard, mouse). ' \
                 'Output devices present data to the user (monitor, speaker). ' \
                 'Storage devices hold data persistently (hard drive, SSD).'
  )

  Rails.logger.info('Seeded 1-1 System Architecture classify questions.')
end

seed_question_tester
seed_classify_system_architecture
