# frozen_string_literal: true

class Subject::CompileSubjectStatistics < ApplicationService
  def initialize(subject = nil)
    @subject = subject
  end

  def call
    questions_this_week = compile_asked_questions_this_week

    OpenStruct.new(success?: true,
                   asked_questions: compile_previous_asked_questions + questions_this_week,
                   asked_questions_this_week: questions_this_week,
                   asked_questions_last_week: 'nyi')
  end

  def compile_previous_asked_questions
    QuestionStatistic.joins(question: { topic: :subject })
                     .where(question: { topics: { subject: @subject } })
                     .sum(:number_asked)
  end

  def compile_asked_questions_this_week
    AskedQuestion.joins(question: { topic: :subject })
                 .where(question: { topics: { subject: @subject } })
                 .count
  end
end
