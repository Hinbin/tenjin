# frozen_string_literal: true

raise "Development lesson seeds can only be loaded in development, not #{Rails.env}." unless Rails.env.development?

# A small pool of real, freely available educational videos. Each topic gets one or
# two lessons drawn from this pool so the seeded database has browsable lesson content.
# The Lesson model extracts the video id from the full URL in a before_save callback,
# so we can pass the share/watch URL straight through as `video_id`.
SEED_LESSON_VIDEOS = [
  { title: 'Introduction to the topic', url: 'https://www.youtube.com/watch?v=zOjov-2OZ0E' },
  { title: 'Key concepts explained',     url: 'https://www.youtube.com/watch?v=8mAITcNt710' },
  { title: 'Worked examples',            url: 'https://www.youtube.com/watch?v=rfscVS0vtbw' },
  { title: 'Common exam questions',      url: 'https://www.youtube.com/watch?v=Y8Tko2YC5hA' },
  { title: 'Revision summary',           url: 'https://youtu.be/_uQrJ0TkZlc' },
  { title: 'Going deeper',               url: 'https://youtu.be/kqtD5dpn9C8' }
].freeze

def seed_lessons_for_topic(topic, lesson_specs)
  lesson_specs.map do |spec|
    title = "#{topic.name}: #{spec[:title]}"

    Lesson.find_or_initialize_by(topic:, title:).tap do |lesson|
      lesson.video_id = spec[:url]
      lesson.save!
      Rails.logger.info("Lesson: #{title}")
    end
  end
end

Topic.find_each.with_index do |topic, index|
  # Give each topic two lessons, rotating through the pool so neighbouring topics differ.
  specs = [
    SEED_LESSON_VIDEOS[index % SEED_LESSON_VIDEOS.length],
    SEED_LESSON_VIDEOS[(index + 1) % SEED_LESSON_VIDEOS.length]
  ]

  lessons = seed_lessons_for_topic(topic, specs)

  # Surface the first lesson on the topic so it shows as the default.
  topic.update!(default_lesson: lessons.first) if topic.default_lesson.blank? && lessons.first.present?
end

# Assign roughly 4 out of every 5 questions to a lesson, rotating evenly across
# the topic's lessons. The remaining 1-in-5 stay unassigned so both states are
# represented in seed data.
Topic.find_each do |topic|
  lessons = topic.lessons.to_a
  next if lessons.empty?

  topic.questions.order(:id).each_with_index do |question, idx|
    lesson_id = idx % 5 < 4 ? lessons[idx % lessons.length].id : nil
    question.update_column(:lesson_id, lesson_id)
  end
end

Rails.logger.info('Development lessons seeded.')
