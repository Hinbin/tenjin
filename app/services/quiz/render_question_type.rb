class Quiz::RenderQuestionType
  def initialize(params)
    @question = params[:question]
  end

  def call
    case @question.question_type
    when 'short_answer'
      'question_short_response'
    else
      'question_multiple_choice'
    end
  end
end
