# frozen_string_literal: true

unless Rails.env.development? || ENV['SEED_TEST_USERS'] == 'true'
  raise "Development question seeds can only be loaded in development or with SEED_TEST_USERS=true, not #{Rails.env}."
end

require 'csv'

@seed_image_blobs = {}
@seed_http_conn = Faraday.new { |builder| builder.adapter Faraday.default_adapter }

def create_file_blob(data:, filename:, content_type:, metadata: nil)
  ActiveStorage::Blob.create_and_upload! io: data, filename: filename,
                                         content_type: content_type, metadata: metadata
end

def upsert_seed_subject(row)
  subject = find_seed_subject(row)
  subject.name = row['name']
  subject.external_id ||= row['id']
  subject.save!
  Rails.logger.info(subject.name)
rescue ActiveRecord::RecordInvalid => e
  handle_seed_subject_error(row, e)
end

def find_seed_subject(row)
  Subject.find_by(external_id: row['id']) || Subject.find_or_initialize_by(name: row['name'])
end

def handle_seed_subject_error(row, error)
  raise error unless error.record.errors.of_kind?(:name, :taken)

  subject = Subject.find_by!(name: row['name'])
  subject.update!(external_id: row['id']) if subject.external_id.blank?
  Rails.logger.info(subject.name)
end

def upsert_seed_topic(row)
  subject = Subject.find_by!(external_id: row['subject_id'])

  find_seed_topic(row, subject).tap do |topic|
    topic.name = row['name']
    topic.subject = subject
    topic.external_id ||= row['id']
    topic.save!
    Rails.logger.info(topic.name)
  end
end

def find_seed_topic(row, subject)
  Topic.find_by(external_id: row['id']) || Topic.find_or_initialize_by(subject:, name: row['name'])
end

def question_text_for_seed(row)
  return row['question_text'] if row['image'].blank?

  image = fetch_seed_image_blob(row['image'])
  return if image.blank?

  %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>#{row['question_text']}</p>)
end

def fetch_seed_image_blob(image_url)
  @seed_image_blobs[image_url] ||= download_seed_image_blob(image_url)
end

def download_seed_image_blob(image_url)
  google_location = image_url.gsub(/open?/, 'uc')
  filename = "#{google_location.from(31)}.png"
  image_location = seed_image_location(google_location, filename)
  return if image_location.blank?

  response = @seed_http_conn.get image_location
  create_file_blob(data: StringIO.new(response.body), filename:, content_type: 'image/jpeg')
end

def seed_image_location(google_location, filename)
  response = @seed_http_conn.get google_location
  location = response.headers['location']
  return location if location.present?
  return google_location if response.success?

  html_image_location(response.body, filename)
end

def html_image_location(response_body, filename)
  href_match = /HREF=".*"/.match(response_body)
  return href_match[0].from(6).chop if href_match

  Rails.logger.info("ERROR WITH: #{filename}")
  nil
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

def seed_question_statistics
  Question.find_each do |question|
    QuestionStatistic.find_or_initialize_by(question:).tap do |stat|
      stat.number_asked = rand(20..500)
      stat.number_correct = stat.number_asked - rand(0..stat.number_asked)
      stat.save!
    end
  end
end

# Build a spread of challenges across topics: a mix of types, plus some that are
# currently running and some that have already finished, so the seeded data exercises
# both states. Idempotent on topic + challenge_type so re-running the seed is safe.
def seed_challenges
  challenge_types = Challenge.challenge_types.keys
  global_index = 0

  Subject.find_each do |subject|
    subject.topics.first(3).each do |topic|
      challenge_type = challenge_types[global_index % challenge_types.length]
      active = global_index.even?

      Challenge.find_or_initialize_by(topic:, challenge_type:).tap do |challenge|
        challenge.daily = false
        challenge.number_required = number_required_for(challenge_type)
        challenge.points = challenge.number_required * 10
        challenge.start_date = active ? 1.day.ago : 14.days.ago
        challenge.end_date = active ? 6.days.from_now : 7.days.ago
        challenge.save!
      end

      global_index += 1
    end
  end
end

def number_required_for(challenge_type)
  case challenge_type
  when 'number_correct' then rand(5..10)
  when 'streak' then rand(3..8)
  else rand(40..60)
  end
end

seed_question_statistics
seed_challenges

Rails.logger.info('Development questions seeded.')
