# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_topic, only: %i[update destroy]

  def new
    @subject = Subject.find(new_topic_params[:subject_id])
    return unless @subject.present?

    authorize @subject
    @topic = Topic.create(subject: @subject, name: 'New topic.  Click here to change name')

    redirect_to questions_path(topic_id: @topic)
  end

  def update
    authorize @topic
    @topic.update(topic_params)
  end

  def destroy
    return if @topic.questions.exists?

    authorize @topic
    @topic.destroy

    redirect_to questions_path
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name)
  end

  def new_topic_params
    params.require(:subject).permit(:subject_id)
  end

end
