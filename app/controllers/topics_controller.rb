# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!

  def new
    subject = Subject.find(new_topic_params[:subject_id])
    topic = Topic.create(subject: subject, active: true, name: "New topic. Click here to change name")
    authorize topic

    redirect_to topic_questions_path(topic_id: topic)
  end

  def update
    topic = authorize find_topic
    topic.update(topic_params)
    head :no_content
  end

  def destroy
    topic = authorize find_topic

    topic.destroy
    redirect_to questions_path
  end

  private

  def find_topic
    Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name, :default_lesson_id)
  end

  def new_topic_params
    params.require(:subject).permit(:subject_id)
  end
end
