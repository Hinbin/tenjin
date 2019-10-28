# frozen_string_literal: true

module QuizzesHelper
  def render_question
    return render('short_answer') if @question.question_type == 'short_answer'

    render('multiple_choice')
  end
end
