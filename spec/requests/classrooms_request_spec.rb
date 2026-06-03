# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Classrooms', :default_creates, type: :request do
  before do
    sign_in school_admin
    classroom
  end

  it 'shows which classrooms have been retrieved from Wonde' do
    get classrooms_path
    expect(response.body).to include(classroom.name)
  end

  it 'allows visiting the classroom assignment page' do
    get classrooms_path
    html = Capybara.string(response.body)
    expect(html).to have_css('a', text: 'Setup Classrooms')
  end
end
