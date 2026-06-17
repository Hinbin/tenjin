# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admins', :default_creates, type: :request do
  context 'when a super admin logs in' do
    it 'allows an admin to access the schools page' do
      sign_in super_admin
      get schools_path
      expect(response.body).to include('Schools')
    end

    it 'shows current admin accounts on the admin page' do
      school_group_admin
      sign_in super_admin
      get admin_path(super_admin)
      html = Capybara.string(response.body)
      expect(html).to have_css('#admins-table .admin-row', count: 2)
      expect(html).to have_text(super_admin.email)
      expect(html).to have_text(school_group_admin.email)
    end

    it 'sends reset password instructions to an admin' do
      school_group_admin
      sign_in super_admin
      expect do
        post reset_password_admin_path(school_group_admin)
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(response).to redirect_to(admin_path(super_admin))
      expect(flash[:notice]).to include(school_group_admin.email)
    end

    it 'removes an admin account' do
      school_group_admin
      sign_in super_admin
      expect do
        delete admin_path(school_group_admin)
      end.to change(Admin, :count).by(-1)
      expect(response).to redirect_to(admin_path(super_admin))
    end

    it 'does not remove my own admin account when another admin remains' do
      school_group_admin
      sign_in super_admin
      expect do
        delete admin_path(super_admin)
      end.not_to change(Admin, :count)
      expect(response).to redirect_to(admin_path(super_admin))
      expect(flash[:alert]).to include('cannot remove your own admin account')
    end

    it 'does not remove the final admin account' do
      sign_in super_admin
      expect do
        delete admin_path(super_admin)
      end.not_to change(Admin, :count)
      expect(response).to redirect_to(admin_path(super_admin))
      expect(flash[:alert]).to include('at least one admin')
    end
  end

  context 'when viewing global statistics' do
    let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }
    let(:new_stat) { create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week) }
    let(:old_stat) { create(:user_statistic, user: create(:student, school: school), week_beginning: two_weeks_ago) }
    let(:new_stat_different_school) { create(:user_statistic, week_beginning: Date.current.beginning_of_week) }
    let(:old_stat_different_school) do
      create(:user_statistic, user: create(:student, school: school), week_beginning: two_weeks_ago)
    end
    let(:total_answered) do
      [new_stat.questions_answered, old_stat.questions_answered,
       new_stat_different_school.questions_answered, old_stat_different_school.questions_answered].sum
    end
    let(:weekly_answered) { new_stat.questions_answered + new_stat_different_school.questions_answered }

    before { sign_in super_admin }

    context 'when looking at questions asked' do
      before do
        new_stat
        old_stat
        new_stat_different_school
        old_stat_different_school
        get show_stats_schools_path
      end

      it 'shows the total number of questions asked across multiple schools' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#asked_questions', exact_text: total_answered.to_s)
      end

      it 'shows the weekly number of questions asked across multiple schools' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#asked_questions_weekly', exact_text: weekly_answered.to_s)
      end
    end

    context 'when looking at homeworks completed' do
      let(:homework_progress) do
        create(:homework_progress, user: student, completed: true, updated_at: Date.current.beginning_of_week)
      end
      let(:old_homework_progress) do
        create(:homework_progress, user: student, completed: true, updated_at: two_weeks_ago)
      end
      let(:homework_progress_different_school) do
        create(:homework_progress, completed: true, updated_at: Date.current.beginning_of_week)
      end
      let(:old_homework_progress_different_school) do
        create(:homework_progress, completed: true, updated_at: two_weeks_ago)
      end

      before do
        homework_progress
        old_homework_progress
        homework_progress_different_school
        old_homework_progress_different_school
        get show_stats_schools_path
      end

      it 'shows the total number of homeworks completed across multiple schools' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#homeworks_completed', exact_text: '4')
      end

      it 'shows the weekly number of homeworks completed across multiple schools' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#homeworks_completed_weekly', exact_text: '2')
      end
    end
  end

  context 'when a school group admin manages their school group' do
    before do
      school
      sign_in school_group_admin
    end

    it 'allows seeing all schools' do
      get schools_path
      expect(response.body).to include(school.name)
    end

    it 'allows seeing a single school' do
      get school_path(school)
      expect(response.body).to include(school.name)
    end

    it 'hides the manage role button' do
      get school_path(school)
      expect(response.body).not_to include('Manage User Roles')
    end

    it 'allows seeing subject statistics' do
      subject
      get subjects_path
      expect(response.body).to include('Questions Asked')
    end

    it 'hides the add school button' do
      get schools_path
      expect(response.body).not_to include('Add School')
    end

    it 'shows the schools menu option' do
      get schools_path
      html = Capybara.string(response.body)
      expect(html).to have_css('.tj-navbar__link', text: 'Schools')
    end

    it 'hides school groups menu option' do
      get schools_path
      html = Capybara.string(response.body)
      expect(html).to have_no_css('.tj-navbar__link', text: 'School Groups')
    end

    it 'hides add subject button' do
      subject
      get subjects_path
      expect(response.body).not_to include('Add Subject')
    end

    it 'hides the roles menu option' do
      get schools_path
      html = Capybara.string(response.body)
      expect(html).to have_no_css('.nav-link', text: 'Roles')
    end
  end

  context 'when a super admin manages user roles' do
    before do
      sign_in super_admin
      teacher
    end

    it 'adds a school admin role' do
      patch set_role_user_path(teacher, user: { role: 'school_admin' })
      expect(teacher.reload.has_role?(:school_admin)).to be true
    end

    it 'removes a school admin role' do
      teacher.add_role :school_admin
      post remove_role_user_path(teacher, user: { role: 'school_admin' })
      expect(teacher.reload.has_role?(:school_admin)).to be false
    end

    it 'adds a question author role' do
      patch set_role_user_path(teacher, user: { role: 'question_author', subject: subject.id })
      expect(teacher.reload.has_role?(:question_author, subject)).to be true
    end

    it 'removes a question author role' do
      teacher.add_role :question_author, subject
      post remove_role_user_path(teacher, user: { role: 'question_author', subject: subject.id })
      expect(teacher.reload.has_role?(:question_author, subject)).to be false
    end

    it 'adds a lesson author role' do
      patch set_role_user_path(teacher, user: { role: 'lesson_author', subject: subject.id })
      expect(teacher.reload.has_role?(:lesson_author, subject)).to be true
    end

    it 'removes a lesson author role' do
      teacher.add_role :lesson_author, subject
      post remove_role_user_path(teacher, user: { role: 'lesson_author', subject: subject.id })
      expect(teacher.reload.has_role?(:lesson_author, subject)).to be false
    end

    it 'shows employees on the manage roles page' do
      get manage_roles_users_path(school: teacher.school)
      html = Capybara.string(response.body)
      expect(html).to have_css('.employee-row', count: 1)
    end
  end

  context 'when a super admin views a school' do
    let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }

    before do
      sign_in super_admin
      school
    end

    it 'links to role management for that school' do
      get school_path(school)
      html = Capybara.string(response.body)
      expect(html).to have_link('Manage User Roles', href: manage_roles_users_path(school:))
    end

    context 'when viewing statistics' do
      let(:statistic) { create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week) }
      let(:older_statistic) do
        create(:user_statistic, user: create(:student, school:), week_beginning: two_weeks_ago)
      end
      let(:total_answered) { statistic.questions_answered + older_statistic.questions_answered }

      before do
        statistic
        older_statistic
        get school_path(school)
      end

      it 'tells you the number of questions asked overall' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#asked_questions', exact_text: total_answered.to_s)
      end

      it 'tells you the number of questions asked this week' do
        html = Capybara.string(response.body)
        expect(html).to have_css('#asked_questions_weekly', exact_text: statistic.questions_answered.to_s)
      end
    end
  end
end
