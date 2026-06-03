# frozen_string_literal: true

module SessionHelpers
  def log_in
    sign_in student
    visit root_path
    expect(page).to have_content('START A QUIZ')
  end

  def stub_omniauth # rubocop:disable Metrics/MethodLength
    OmniAuth.config.logger = Rails.logger
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:wonde] =
      OmniAuth::AuthHash.new(
        'provider' => 'wonde',
        'uid' => nil,
        'info' => {},
        'credentials' =>
         { 'token' => 'mock-wonde-access-token',
           'refresh_token' => 'mock-wonde-refresh-token',
           'expires_at' => 1_546_160_571,
           'expires' => true },
        'extra' => {}
      )
  end

  def stub_google_omniauth
    # first, set OmniAuth to run in test mode
    OmniAuth.config.test_mode = true
    # then, provide a set of fake oauth data that
    # omniauth will use when a user tries to authenticate:
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      'provider' => 'google_oauth2',
      'uid' => '123456123456',
      'info' =>
         { 'name' => 'Test',
           'email' => 'test@test.com',
           'unverified_email' => 'test@test.com',
           'email_verified' => true,
           'first_name' => 'Test',
           'last_name' => 'Person' }
    )
  end

  def setup_subject_database
    create(:enrollment, classroom:, user: student)
    create(:multiplier)
  end

  def navigate_to_quiz
    visit(new_quiz_path(subject: subject.name))
    select Topic.last.name, from: 'quiz_topic_id'
    click_button('Create Quiz')
    find('.trix-content')
  end

  def navigate_to_lucky_dip
    visit(new_quiz_path(subject: subject.name))
    select 'Lucky Dip', from: 'quiz_topic_id'
    click_button('Create Quiz')
  end

  def create_homework
    find('input#homework_due_date').click
    find(flatpickr_one_week_from_now).click
    select '70', from: 'Required %'
    select topic.name, from: 'Topic'
    click_button('Set Homework')
  end

  def create_homework_for_lesson
    find('input#homework_due_date').click
    find(flatpickr_one_week_from_now).click
    select '70', from: 'Required %'
    select topic.name, from: 'Topic'
    select lesson.title, from: 'Lesson'
    click_button('Set Homework')
  end

  def initialize_name(user)
    "#{user.forename} #{user.surname[0]}"
  end

  def log_in_through_front_page(username, password)
    visit(root_path)
    click_button 'Login'
    fill_in('user_login', with: username)
    fill_in('user_password', with: password)
    click_button 'loginModal'
    find('.alert', text: 'Signed in successfully')
  end

  def update_password(new_password)
    find_by_id('user_password').set(new_password)
    click_button('Update Password')
    find('.alert')
  end

  def create_file_blob(filename:, content_type:, metadata: nil)
    ActiveStorage::Blob.create_and_upload! io: file_fixture(filename).open, filename:,
                                           content_type:, metadata:
  end
end
