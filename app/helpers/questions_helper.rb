# frozen_string_literal: true

module QuestionsHelper
  def flag_icon
    if @flagged_question.present? && @flagged_question.persisted?
      icon('fas', 'flag', class: 'fa', style: 'color: red')
    else
      icon('far', 'flag', class: 'fa', style: 'color: red')
    end
  end

  def percentage_correct(question)
    qs = question.question_statistic
    return '0%' unless qs.present?

    number_to_percentage((qs.number_correct.to_f / qs.number_asked) * 100, precision: 0)
  end

  def times_asked(question)
    question.question_statistic.present? ? question.question_statistic.number_asked : 0
  end
end
