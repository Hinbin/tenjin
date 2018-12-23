require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe 'get #show' do
    it 'displays the dashboard' do
      sign_in create(:student)
      get :show
      expect(response).to render_template(:show)
    end
  end

end
