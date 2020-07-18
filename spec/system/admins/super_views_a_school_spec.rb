# frozen_string_literal: true

RSpec.describe 'Super views a school', type: :system, js: true, default_creates: true do
  let(:new_email) { FFaker::Internet.email }
  let(:save_email_notice) { "Updated email to #{school_admin.forename} #{school_admin.surname}" }
  let(:email_notice) do
    "Setup email sent to #{school_admin.forename} #{school_admin.surname} (#{school_admin.email})"
  end

  before do
    sign_in super_admin
    school
  end

  it 'allows you to become a student' do
    student
    visit(school_path(school))
    click_button('Become User')
    expect(page).to have_css('#current_user', text: "#{student.forename} #{student.surname}")
  end

  it 'allows you to become a school admin' do
    school_admin
    visit school_path(school)
    within('#schoolAdminTable') { click_link 'Become User' }
    expect(page).to have_css('#current_user', text: "#{school_admin.forename} #{school_admin.surname}")
  end

  it 'links to role management for that school' do
    visit(school_path(school))
    click_link 'Manage User Roles'
    expect(page).to have_current_path(manage_roles_users_path(school: school))
  end

  it 'saves email addresses of school admins' do
    school_admin
    visit(school_path(school))
    fill_in "user-email-#{school_admin.id}", with: new_email
    find("#save-email-#{school_admin.id}").click
    expect(page).to have_css('#flash-notice', text: save_email_notice)
  end

  it 'notifies users that a setup email has been sent' do
    school_admin
    visit(school_path(school))
    click_link 'Send Setup Email'
    expect(page).to have_css('#flash-notice', text: email_notice, wait: 6)
  end

  context 'when viewing statistics' do
    let(:statistic) { create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week) }
    let(:older_statistic) do
      create(:user_statistic, user: create(:student, school: school),
                              week_beginning: two_weeks_ago)
    end
    let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }
    let(:total_answered) { statistic.questions_answered + older_statistic.questions_answered }

    before do
      statistic
      older_statistic
      visit(school_path(school))
    end

    it 'tells you the number of questions asked overall' do
      expect(page).to have_css('#asked_questions', exact_text: total_answered)
    end

    it 'tells you the number of questions asked this week' do
      expect(page).to have_css('#asked_questions_weekly', exact_text: statistic.questions_answered)
    end
  end
end
