# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show update gaps student_gap]

  def index
    authorize current_user.school, :sync?
    @classrooms = policy_scope(Classroom).order(:name)
    @school = current_user.school
    @subjects = Subject.where(active: true)
  end

  def show
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: 'student', enrollments: { classroom: @classroom })
    @fast_flag_counts = AskedQuestion.fast_flag_counts(@students.map(&:id))
    @homeworks = @classroom.homework_counts

    @homework_progress = HomeworkProgress.joins(:homework)
                                         .where(homework: @homeworks.pluck(:id))
                                         .order('homeworks.due_date desc')
  end

  def update
    authorize @classroom
    @classroom.update(subject_id: update_classroom_params[:subject])
    @classroom.school.update(sync_status: 'needed')
  end

  # Gap-analysis overview: every class this teacher can drill into, with a cheap engagement summary
  # (Analytics::ClassGapSummary — not the full report) so the page stays fast.
  def gap_analysis
    authorize current_user, :show?, policy_class: DashboardPolicy
    classrooms = Enrollment.includes(classroom: %i[school subject])
                           .where(user: current_user)
                           .map(&:classroom)
                           .select { |c| c.subject.present? && policy(c).gaps? }
                           .uniq
    @class_summaries = classrooms.map { |c| [c, Analytics::ClassGapSummary.call(c)] }
  end

  def gaps
    authorize @classroom, :gaps?
    @report = Analytics::ClassGapReport.call(@classroom)
  end

  def student_gap
    authorize @classroom, :gaps?
    @student = @classroom.users.find(params.expect(:student_id))
    @report = Analytics::StudentGapReport.call(@student, @classroom)
  end

  private

  def set_classroom
    @classroom = Classroom.find(params.expect(:id))
  end

  def update_classroom_params
    params.permit(:subject, :id)
  end
end
