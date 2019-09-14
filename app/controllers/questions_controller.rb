class QuestionsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_question, only: %i[show update destroy]

  def index
    if question_params[:topic_id].present?
      @topic = policy_scope(Topic).find(question_params[:topic_id])
      @questions = Question.clean_empty_questions(@topic)

      return render 'question_topic_index'
    end

    @subjects = policy_scope(Subject).includes(:topics)
  end

  def new
    @topic = Topic.find(new_question_params[:topic_id])
    return unless @topic.present?

    authorize @topic
    @question = Question.create(topic: @topic, question_type: 'multiple')
    Answer.create(question: @question, text: 'Click to edit this answer', correct: false)

    redirect_to @question
  end

  def show
    authorize @question.topic
  end

  def update
    authorize @question.topic
    @question.update(question_update_params)

    @question.save unless @question.question_text.to_plain_text.blank?

    if request.xhr?
      head :ok
    else
      redirect_to @question
    end
  end

  def destroy
    authorize @question.topic
    redirect_to questions_path(topic_id: @question.topic)

    @question.answers.destroy_all
    @question.destroy
  end

  private

  def question_params
    params.permit(:topic_id)
  end

  def question_update_params
    params.require(:question).permit(:question_text, :question_type)
  end

  def set_question
    @question = Question.find(params[:id])
  end

  def new_question_params
    params.require(:topic).permit(:topic_id)
  end
end
