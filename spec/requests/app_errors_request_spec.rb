# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'App errors', :default_creates, type: :request do
  let!(:app_error) { AppError.create!(exception_class: 'StandardError', message: 'boom', environment: Rails.env) }

  it 'allows super admins to view runtime errors' do
    sign_in super_admin

    get app_errors_path

    expect(response.body).to include('Runtime Errors')
    expect(response.body).to include('StandardError')
  end

  it 'allows super admins to view a runtime error from the list page' do
    sign_in super_admin

    get app_error_path(app_error)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('StandardError')
    expect(response.body).to include('boom')
  end

  it 'does not allow school group admins to view runtime errors' do
    sign_in school_group_admin

    get app_errors_path

    expect(response).to redirect_to(root_path)
  end
end
