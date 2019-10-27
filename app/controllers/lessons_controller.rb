# frozen_string_literal: true

class LessonsController < ApplicationController
  def index
    @author = current_user.has_role? :lesson_author, :any

    if @author
      @editable_subjects = Subject.with_role(:lesson_author, current_user)
      @lessons = policy_scope(Lesson).or( Lesson.includes(:topic).where(topics: { subject: @editable_subjects.pluck(:id) }) )
    else
      @lessons = policy_scope(Lesson)
    end

    @topics = Topic.joins(:lessons).where(id: @lessons.pluck(:topic_id)).uniq
    @subjects = Subject.where(topics: @topics)
  end

  def new
    first_topic = Topic.where(subject: Subject.find(new_lesson_params)).first
    redirect_to lessons_path flash: { error: 'No topics found for subject' } unless first_topic.present?

    @lesson = Lesson.new
    @lesson.topic = first_topic
    @topics = Topic.where(subject: Subject.find(new_lesson_params))
    authorize @lesson
  end

  def create
    @lesson = Lesson.new(create_lesson_params)
    authorize @lesson

    unless @lesson.valid?
      @topics = Topic.where(subject: @lesson.topic.subject)
      return render 'new'
    end

    url = @lesson.url.match(%r{http(?:s?)://(?:www\.)?youtu(?:be\.com/watch\?v=|\.be/)([\w\-\_]*)(&(amp;)?‌​[\w\?‌​=]*)?}).captures
    @lesson.video_id = url[0]
    @lesson.category = 'video'
    @lesson.save!

    redirect_to lessons_path
  end

  private

  def new_lesson_params
    params.require(:subject)
  end

  def create_lesson_params
    params.require(:lesson).permit(:url, :title, :topic_id)
  end
end
