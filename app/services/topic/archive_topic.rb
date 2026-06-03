# frozen_string_literal: true

class Topic::ArchiveTopic < ApplicationService
  def initialize(topic)
    super()
    @topic = topic
  end

  def call
    ActiveRecord::Base.transaction do
      @topic.update!(active: false)
      @topic.challenges.where('end_date > ?', Time.current).destroy_all
    end

    result(success: true, errors: nil)
  rescue ActiveRecord::ActiveRecordError => e
    AppErrorReporter.report(e, context: { topic_id: @topic.id, topic_name: @topic.name })
    result(success: false, errors: 'Topic could not be archived. The failure has been recorded.')
  end
end
