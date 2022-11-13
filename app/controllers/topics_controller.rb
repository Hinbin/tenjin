# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic, only: %i[update edit show destroy]

  def index
    @subjects = policy_scope(Question)
    raise Pundit::NotAuthorizedError if @subjects.blank?
  end

  def new
    @subject = Subject.find(new_topic_params[:subject_id])
    return unless @subject.present?

    @topic = Topic.create(subject: @subject, active: true, name: 'New topic.  Click here to change name')
    authorize @topic

    redirect_to topic_path(@topic)
  end

  def show
    authorize @topic

    @topic_lessons = Lesson.where(topic: @topic)
    @questions = Question.with_rich_text_question_text_and_embeds
                         .includes(:question_statistic, :lesson)
                         .where(topic: @topic, active: true)
  end

  def edit
    authorize @topic

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@topic, partial: 'topic_edit') }
      format.html         { render 'edit' }
    end
  end

  def update
    authorize @topic
    @topic.update(topic_params)

    respond_to do |format|
      format.html         { redirect_to topic_path(@topic) }
    end
  end

  def destroy
    authorize @topic

    @topic.destroy
    redirect_to topics_path
  end

  def flagged_questions
    @subject = Subject.find(flagged_questions_params)
    authorize @subject, :flagged_questions?
    @questions = @subject.flagged_questions
    render :flagged
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name, :default_lesson_id)
  end

  def new_topic_params
    params.require(:subject).permit(:subject_id)
  end

  def flagged_questions_params
    params.require(:subject_id)
  end

end
