module QuestionsHelper
  def flag_icon
    if @flagged_question.present? && @flagged_question.persisted?
      icon('fas', 'flag', class: 'fa', style: 'color: red')
    else
      icon('far', 'flag', class: 'fa', style: 'color: red')
    end
  end
end