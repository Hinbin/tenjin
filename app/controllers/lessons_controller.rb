# frozen_string_literal: true

class LessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lesson, only: %i[edit update destroy]

  def index
    @author = current_user.has_role? :lesson_author, :any

    if @author
      @editable_subjects = Subject.with_role(:lesson_author, current_user)
      @lessons = policy_scope(Lesson)
                 .or(Lesson
                  .includes(:topic)
                  .where(topics: { subject: @editable_subjects.pluck(:id) }))
    else
      @lessons = policy_scope(Lesson)
    end

    @topics = Topic.joins(:lessons).where(id: @lessons.pluck(:topic_id)).uniq
    @subjects = Subject.where(topics: @topics)
  end

  def new
    first_topic = Topic.where(active: true, subject: Subject.find(new_lesson_params)).first
    redirect_to lessons_path flash: { error: 'No topics found for subject' } unless first_topic.present?

    @lesson = Lesson.new
    @lesson.topic = first_topic
    @topics = Topic.where(active: true, subject: Subject.find(new_lesson_params)).order(:name)
    authorize @lesson
  end

  def create
    @lesson = Lesson.new(lesson_params)
    save_lesson
  end

  def edit
    @topics = Topic.where(active: true, subject: @lesson.subject).order(:name)
    @lesson.video_id = @lesson.generate_video_src
    authorize @lesson
  end

  def update
    authorize @lesson
    @lesson.assign_attributes(lesson_params)

    save_lesson
  end

  def destroy
    authorize @lesson
    @lesson.destroy
    redirect_to lessons_path
  end

  private

  def set_lesson
    @lesson = Lesson.find(params[:id])
  end

  def save_lesson
    authorize @lesson

    unless @lesson.valid?
      @topics = policy_scope(Topic).where(subject: @lesson.topic.subject)

      return render 'edit' if @lesson.persisted?

      return render 'new'
    end

    @lesson.save!

    redirect_to lessons_path
  end

  def new_lesson_params
    params.require(:subject)
  end

  def lesson_params
    params.require(:lesson).permit(:title, :video_id, :topic_id)
  end
end
