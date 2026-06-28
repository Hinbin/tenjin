# frozen_string_literal: true

class Topic::DestroyTopic < ApplicationService
  def initialize(topic)
    super()
    @topic = topic
  end

  def call
    ActiveRecord::Base.transaction do
      lesson_ids = @topic.lessons.pluck(:id)

      clear_lesson_references(lesson_ids)
      preserve_usage_history
      @topic.update!(default_lesson_id: nil)
      @topic.destroy!
    end

    result(success: true, errors: nil)
  rescue ActiveRecord::ActiveRecordError => e
    AppErrorReporter.report(e, context: failure_context)
    result(success: false, errors: 'Topic could not be deleted. The failure has been recorded.')
  end

  private

  def clear_lesson_references(lesson_ids)
    return if lesson_ids.blank?

    Homework.where(lesson_id: lesson_ids).update_all(lesson_id: nil)
    Quiz.where(lesson_id: lesson_ids).update_all(lesson_id: nil)
    UsageStatistic.where(lesson_id: lesson_ids).update_all(lesson_id: nil)
    Question.where(lesson_id: lesson_ids).update_all(lesson_id: nil)
  end

  def preserve_usage_history
    UsageStatistic.where(topic: @topic).update_all(topic_id: nil)
  end

  def failure_context
    { topic_id: @topic.id,
      topic_name: @topic.name,
      question_count: @topic.questions.count,
      lesson_count: @topic.lessons.count,
      homework_count: @topic.homeworks.count,
      quiz_count: @topic.quizzes.count,
      challenge_count: @topic.challenges.count,
      usage_statistic_count: @topic.usage_statistics.count,
      import_count: @topic.imports.count }
  end
end
