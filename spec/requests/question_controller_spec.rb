# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'using question editing', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:author) { create(:author) }

  context 'when I am a student' do
    it 'redirects me to the dashboard' do
      sign_in student
      get questions_path
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  context 'when viewing questions for a topic' do
    before do
      sign_in author
    end

    it 'displays the questions index page' do
      get questions_path
      expect(response).to render_template(:index)
    end
  end
end
