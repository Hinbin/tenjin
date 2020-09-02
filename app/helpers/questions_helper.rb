# frozen_string_literal: true

module QuestionsHelper
  def flag_icon
    if @flagged_question.present? && @flagged_question.persisted?
      "<img class='fas fa-flag' style='color: red'></img>".html_safe
    else
      "<img class='far fa-flag' style='color: red'></img>".html_safe
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
