# frozen_string_literal: true

RSpec.describe 'Super views all schools', type: :system, js: true, default_creates: true do

  before do
    sign_in super_admin
  end

  it 'shows questions asked per school'
end