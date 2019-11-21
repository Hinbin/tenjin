# frozen_string_literal: true

module QuestionsHelper
  def flag_icon
    if @flagged_question.present? && @flagged_question.persisted?
      icon('fas', 'flag', class: 'fa', style: 'color: red')
    else
      icon('far', 'flag', class: 'fa', style: 'color: red')
    end
  end

  def calculate_percentage_correct(q)
    return '0%' if q.asked_questions.empty?

    number_to_percentage((q.asked_questions.where(correct: true).size.to_f / q.asked_questions.size) * 100,
                         precision: 0)
  end
end
