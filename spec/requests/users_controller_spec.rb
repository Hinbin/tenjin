# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'user controller', default_creates: true, type: :request do
  before do
    student
  end

  def reset_all_link
    patch reset_all_passwords_school_path(student.school)
  end

  context 'when I am not authorized to perform this action' do
    it 'does not succeed if I am an employee' do
      sign_in teacher
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it 'does not succeed if I am a student' do
      sign_in student
      reset_all_link
      expect(response).to redirect_to(root_path)
    end

    it 'displays a flash notice if unsuccessful' do
      sign_in student
      reset_all_link
      expect(flash[:alert]).to be_present
    end
  end

  context 'when managing roles' do
    it 'only adds roles to employees' do
      sign_in super_admin
      student
      patch set_role_user_path(student, user: { role: 'school_admin', subject: school })
      expect(response).to redirect_to(root_path)
    end

    it 'only allows me to add roles if I am a super admin' do
      sign_in student
      patch set_role_user_path(teacher, user: { role: 'school_admin', subject: school })
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end

RSpec.describe 'employee views a student record', default_creates: true, type: :request do
  let(:second_classroom) { create(:classroom, school:) }
  let(:homework_different_class) { create(:homework, classroom: second_classroom, topic:) }
  let(:enrollment_different_class) { create(:enrollment, user: student, classroom: second_classroom) }
  let(:different_employee) { create(:teacher, school:) }

  before do
    sign_in teacher
    create(:enrollment, user: student, classroom:)
    create(:enrollment, user: teacher, classroom:)
    homework
  end

  it 'opens the student record' do
    get user_path(student)
    expect(response).to have_http_status(:ok)
  end

  it 'shows uncompleted homeworks' do
    get user_path(student)
    html = Capybara.string(response.body)
    expect(response.body).to include(homework.topic.name)
    expect(html).to have_css('svg.fa-times')
  end

  it 'shows recently completed homeworks' do
    HomeworkProgress.all.update_all(completed: true)
    get user_path(student)
    expect(response).to have_http_status(:ok)
  end

  it 'only shows the homeworks for the classes the teacher belongs to' do
    enrollment_different_class
    homework_different_class
    get user_path(student)
    html = Capybara.string(response.body)
    expect(html).to have_no_css("tr[data-homework='#{homework_different_class.id}'")
  end

  it 'does not allow resetting an employee password' do
    get user_path(different_employee)
    html = Capybara.string(response.body)
    expect(html).to have_no_css('#user_password')
  end

  it 'does not allow resetting a school admin password' do
    get user_path(school_admin)
    html = Capybara.string(response.body)
    expect(html).to have_no_css('#user_password')
  end
end

RSpec.describe 'school admin views a student record', default_creates: true, type: :request do
  before { create(:enrollment, user: student, classroom:) }

  it 'shows the user password reset option for a school admin' do
    sign_in school_admin
    get user_path(student)
    expect(response.body).to include('Update Password')
  end

  it 'tells the user the password has been updated' do
    sign_in school_admin
    patch user_path(student), params: { user: { password: new_password } }
    follow_redirect!
    expect(response.body).to include('Password successfully updated')
  end

  it 'shows the user password reset option for an employee' do
    sign_in teacher
    get user_path(student)
    expect(response.body).to include('Update Password')
  end

  it 'shows the user password reset option for a student viewing their own account' do
    sign_in student
    get user_path(student)
    expect(response.body).to include('Update Password')
  end
end

RSpec.describe 'school admin views an employee record', default_creates: true, type: :request do
  it 'shows the user password reset option for a school admin' do
    sign_in school_admin
    get user_path(teacher)
    expect(response.body).to include('Update Password')
  end

  it 'shows the user password reset option for an employee viewing their own record' do
    sign_in teacher
    get user_path(teacher)
    expect(response.body).to include('Update Password')
  end
end

RSpec.describe 'school admin views user list', default_creates: true, type: :request do
  before do
    sign_in school_admin
  end

  it 'does not allow a teacher to view the page' do
    sign_in teacher
    get users_path
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to be_present
  end

  it 'does not allow a student to view the page' do
    sign_in student
    get users_path
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to be_present
  end

  it 'shows a list of students belonging to the school' do
    create(:enrollment, classroom:, user: teacher)
    create_list(:enrollment, 5, classroom:, school:)
    get users_path
    expect(response.body).to include(User.where(role: 'student', school:).first.surname)
  end

  it 'does not show students that belong to another school' do
    create(:enrollment, school: second_school)
    get users_path
    expect(response.body).not_to include(User.where(role: 'student', school: second_school).first.surname)
  end

  it 'shows employees if I am a school admin' do
    create(:teacher, school:)
    get users_path
    html = Capybara.string(response.body)
    expect(html).to have_css('.employee-row', count: 2)
  end

  it 'shows other school admins if I am a school admin' do
    create(:school_admin, school:)
    get users_path
    html = Capybara.string(response.body)
    expect(html).to have_css('.employee-row', count: 2)
  end
end
