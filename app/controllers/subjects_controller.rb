# frozen_string_literal: true

class SubjectsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @subjects = policy_scope(Subject).order(:name).where(active: true)
    @deactivated_subjects = Subject.where(active: false)
    all_subject_ids = (@subjects + @deactivated_subjects).map(&:id)
    @question_counts = Question.joins(topic: :subject)
      .where(topics: {subject_id: all_subject_ids})
      .group("topics.subject_id")
      .count
    @subject_statistics = @subjects.each_with_object({}) do |subject, h|
      h[subject.id] = Subject::CompileSubjectStatistics.call(subject)
    end
  end

  def show
    @subject = authorize find_subject
  end

  def new
    @subject = Subject.new
    authorize @subject
  end

  def create
    @subject = Subject.new(subject_params)
    authorize @subject

    if @subject.save
      redirect_to @subject
    else
      render :new
    end
  end

  def update
    subject = authorize find_subject
    subject.update(subject_params)
    redirect_to subject
  end

  def destroy
    subject = authorize find_subject
    subject.update_attribute(:active, false)

    Enrollment.joins(:classroom).where(classrooms: {subject_id: subject}).destroy_all
    Classroom.where(subject: subject).update_all(subject_id: nil)
    redirect_to subjects_path
  end

  private

  def find_subject
    Subject.find(params[:id])
  end

  def subject_params
    params.require(:subject).permit(:name, :active)
  end
end
