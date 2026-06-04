# frozen_string_literal: true

unless Rails.env.development?
  raise "Development question seeds can only be loaded in development, not #{Rails.env}."
end

require 'csv'

def create_file_blob(data:, filename:, content_type:, metadata: nil)
  ActiveStorage::Blob.create_after_upload! io: data, filename: filename,
                                           content_type: content_type, metadata: metadata
end

def upsert_seed_subject(row)
  Subject.find_or_initialize_by(external_id: row['id']).tap do |subject|
    subject.name = row['name']
    subject.save!
    p subject.name
  end
rescue ActiveRecord::RecordInvalid => e
  raise e unless e.record.errors.of_kind?(:name, :taken)

  Subject.find_by!(name: row['name']).tap do |subject|
    subject.update!(external_id: row['id']) if subject.external_id.blank?
    p subject.name
  end
end

def upsert_seed_topic(row)
  subject = Subject.find_by!(external_id: row['subject_id'])

  Topic.find_or_initialize_by(external_id: row['id']).tap do |topic|
    topic.name = row['name']
    topic.subject = subject
    topic.save!
    p topic.name
  end
end

def question_text_for_seed(row)
  return row['question_text'] if row['image'].blank?

  google_location = row['image'].gsub(/open?/, 'uc')
  http_conn = Faraday.new { |builder| builder.adapter Faraday.default_adapter }
  response = http_conn.get google_location
  filename = google_location.from(31) + '.png'
  href_match = /HREF=".*"/.match(response.body)

  unless href_match
    p "ERROR WITH: #{filename}"
    return nil
  end

  response = http_conn.get href_match[0].from(6).chop
  image = create_file_blob(data: StringIO.new(response.body), filename:, content_type: 'image/jpeg')
  %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>#{row['question_text']}</p>)
end

def upsert_seed_question(row)
  topic = Topic.find_by!(external_id: row['topic_id'])
  question_text = question_text_for_seed(row)
  return if question_text.blank?

  Question.find_or_initialize_by(external_id: row['id']).tap do |question|
    question.topic = topic
    question.question_text = question_text
    question.question_type = row['question_type']
    question.save!(validate: false)
  end
end

def flush_seed_answers(answer_rows)
  answer_rows.shuffle.each do |row|
    question = Question.find_by(external_id: row['question_id'])
    next if question.blank?

    Answer.find_or_initialize_by(external_id: row['id'], question:).tap do |answer|
      answer.text = row['text']
      answer.correct = ActiveModel::Type::Boolean.new.cast(row['correct'])
      answer.save!
    end
  end
end

if File.exist?('db/CSV Output - subject_export.csv')
  CSV.foreach('db/CSV Output - subject_export.csv', headers: true) do |row|
    upsert_seed_subject(row)
  end
end

if File.exist?('db/CSV Output - unit_export.csv')
  CSV.foreach('db/CSV Output - unit_export.csv', headers: true) do |row|
    upsert_seed_topic(row)
  end
end

if File.exist?('db/CSV Output - question_export.csv')
  CSV.foreach('db/CSV Output - question_export.csv', headers: true) do |row|
    upsert_seed_question(row)
  end
end

# Answers from the Google spreadsheets come in a set order, with correct answer first.
# Randomise these answers.
if File.exist?('db/CSV Output - answer_export.csv')
  question_id = nil
  answer_rows = []

  CSV.foreach('db/CSV Output - answer_export.csv', headers: true) do |row|
    if question_id.present? && question_id != row['question_id']
      flush_seed_answers(answer_rows)
      answer_rows = []
    end

    answer_rows.push(row)
    question_id = row['question_id']
  end

  flush_seed_answers(answer_rows)
end

puts 'Development questions seeded.'
