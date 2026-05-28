# frozen_string_literal: true

class SubjectsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @subjects, @deactivated_subjects = policy_scope(Subject).order(:name).partition(&:active?)
    @question_counts = Question.counts_by_subject
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
