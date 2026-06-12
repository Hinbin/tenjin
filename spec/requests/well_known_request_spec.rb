# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Well-known routes' do
  describe 'GET /.well-known/appspecific/com.chrome.devtools.json' do
    it 'returns no content for Chrome DevTools discovery requests' do
      get '/.well-known/appspecific/com.chrome.devtools.json'

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end
  end
end
