# frozen_string_literal: true

module System
  class SchoolsController < BaseController
    def index
      @schools = policy_scope(School).order(:name)
      @school_groups = policy_scope(SchoolGroup).order(:name)
      school_ids = @schools.pluck(:id)
      @student_counts = User.where(school_id: school_ids, role: :student).group(:school_id).count
      @weekly_questions = UserStatistic.joins(:user)
        .where(users: {school_id: school_ids}, week_beginning: Date.current.beginning_of_week)
        .group("users.school_id").sum(:questions_answered)
      @monthly_questions = UserStatistic.joins(:user)
        .where(users: {school_id: school_ids}, week_beginning: 1.month.ago.to_date..Date.current)
        .group("users.school_id").sum(:questions_answered)
    end

    def stats
      authorize current_admin, :show_stats?
      @school_statistics = School::Statistics.new
      @customisation_statistics = Customisation.select(:name, :customisation_type, "COUNT(customisations.id)")
        .left_joins(:customisation_unlocks)
        .group(:id)
        .order(count: :desc)
      render "overall_statistics"
    end

    def show
      @school = authorize find_school
      @school_statistics = School::Statistics.new(@school)
      @school_admins = User.where(school: @school).with_role(:school_admin)
      @users = User.where(school: @school)
    end

    def new
      @school = School.new
      authorize @school
    end

    def create
      @school = School::AddSchool.call(school_params)
      authorize @school
      if @school.persisted?
        SyncSchoolJob.perform_later @school
        redirect_to [:system, @school]
      else
        render :new
      end
    end

    def update
      school = authorize find_school
      school.update(update_school_params)
      head :no_content
    end

    def sync
      school = authorize find_school
      school.update_attribute(:sync_status, "queued")
      SyncSchoolJob.perform_later school
      head :no_content
    end

    private

    def find_school
      School.find(params[:id])
    end

    def school_params
      params.require(:school).permit(:client_id, :token)
    end

    def update_school_params
      params.require(:school).permit(:school_group_id, :permitted)
    end
  end
end
