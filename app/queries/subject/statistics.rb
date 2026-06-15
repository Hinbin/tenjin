# frozen_string_literal: true

# Aggregates question-asked counts for a single subject, optionally scoped by week.
# Constructed cheaply; each method runs its query once and memoizes the result.
class Subject::Statistics
  def initialize(subject = nil)
    @subject = subject
  end

  def asked_questions
    @asked_questions ||= previous_asked_questions + asked_questions_this_week
  end

  def asked_questions_this_week
    @asked_questions_this_week ||= AskedQuestion.joins(question: {topic: :subject})
      .where(question: {topics: {subject: @subject}})
      .count
  end

  private

  def previous_asked_questions
    QuestionStatistic.joins(question: {topic: :subject})
      .where(question: {topics: {subject: @subject}})
      .sum(:number_asked)
  end
end
