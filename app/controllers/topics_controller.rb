# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic, only: %i[update destroy]

  def new
    @subject = Subject.find(new_topic_params[:subject_id])
    return unless @subject.present?

    @topic = Topic.create(subject: @subject, active: true, name: 'New topic.  Click here to change name')
    authorize @topic

    redirect_to topic_questions_questions_path(topic_id: @topic)
  end

  def update
    authorize @topic
    @topic.update(topic_params)
  end

  def destroy
    authorize @topic

    @topic.destroy
    redirect_to questions_path
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
end
