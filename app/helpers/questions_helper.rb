# frozen_string_literal: true

module QuestionsHelper
  def flag_icon
    if @flagged_question.present? && @flagged_question.persisted?
      icon('fas', 'flag', class: 'fa', style: 'color: red')
    else
      icon('far', 'flag', class: 'fa', style: 'color: red')
    end
  end

  def percentage_correct(q)
    return '0%' unless q.question_statistic.present?

    number_to_percentage((q.question_statistic.number_correct.to_f / q.question_statistic.number_asked) * 100,
                         precision: 0)
  end

  def times_asked(q)
    q.question_statistic.present? ? q.question_statistic.number_asked : 0
  end
end
