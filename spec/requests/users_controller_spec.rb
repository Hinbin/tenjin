require 'rails_helper'

RSpec.describe 'resetting all user passwords', default_creates: true, type: :request do
  before do
    student
  end

  def reset_all_link
    post '/users', params: { reset_all: true }
  end

  context 'when submitting a password change for all' do
    it 'displays the new password template if sucessful' do
      sign_in school_admin
      reset_all_link
      expect(response).to render_template('new_passwords')
    end
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
end
