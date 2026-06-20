# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:, motion_pref: true) }

  before { sign_in student }

  describe 'GET /settings' do
    it 'returns 200 for authenticated students' do
      get settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /settings (motion preference)' do
    it 'persists motion_pref false and redirects back' do
      patch settings_path, params: { motion_pref: false }
      expect(response).to redirect_to(settings_path)
      expect(student.reload.motion_pref).to be(false)
    end

    it 'persists motion_pref true' do
      student.update!(motion_pref: false)
      patch settings_path, params: { motion_pref: true }
      expect(student.reload.motion_pref).to be(true)
    end
  end

  describe 'GET /settings (unauthenticated)' do
    before { sign_out student }

    it 'redirects to login' do
      get settings_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
