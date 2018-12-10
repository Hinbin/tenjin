class Quiz::RenderQuestionType
  def initialize(params)
    @question = params[:question]
  end

  def call
    if @question.answers_count == 1
      'question_short_response'
    else
      'question_multiple_choice'
    end
  end
end
