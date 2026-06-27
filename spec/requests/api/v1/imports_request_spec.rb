# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Imports', :default_creates, type: :request do
  let(:token) { 'test-import-token' }
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('IMPORT_API_TOKEN').and_return(token)
  end

  def import(payload, topic_id: topic.id, filename: 'computer-systems', headers: auth_headers)
    post api_v1_imports_path(topic_id:, filename:), params: payload.to_json, headers: headers
  end

  describe 'authentication' do
    it 'rejects a missing token' do
      import(ImportPayloads.all_engine_types, headers: { 'Content-Type' => 'application/json' })
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a wrong token' do
      import(ImportPayloads.all_engine_types,
             headers: auth_headers.merge('Authorization' => 'Bearer nope'))
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'topic resolution' do
    it 'returns 404 for an unknown topic' do
      import(ImportPayloads.all_engine_types, topic_id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'a successful import' do
    before { import(ImportPayloads.all_engine_types) }

    it 'returns 200 with counts' do
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['imported']).to eq(6)
      expect(body['updated']).to eq(0)
      expect(body['errors']).to be_empty
    end

    it 'creates one valid question of every engine type' do
      expect(topic.questions.pluck(:question_type)).to match_array(
        %w[short_answer multiple fill_blank ordering matrix classify]
      )
    end

    it 'creates every question as pending and inactive' do
      expect(topic.questions).to all(have_attributes(review_status: 'pending', active: false))
    end

    it 'writes one audit row' do
      expect(Import.count).to eq(1)
      expect(Import.last).to have_attributes(topic:, imported_count: 6, filename: 'computer-systems')
    end
  end

  describe 're-pushing the same payload' do
    before { import(ImportPayloads.all_engine_types) }

    it 'updates in place without creating duplicates' do
      expect { import(ImportPayloads.all_engine_types) }.not_to change(Question, :count)
    end

    it 'reports the updates as updated, not imported' do
      import(ImportPayloads.all_engine_types)
      body = response.parsed_body
      expect(body['imported']).to eq(0)
      expect(body['updated']).to eq(6)
    end
  end

  describe 'a partly invalid batch' do
    let(:batch) do
      [ImportPayloads.short_answer, ImportPayloads.multiple.merge(question_text: '')]
    end

    before { import(batch) }

    it 'imports the valid question and reports the invalid one' do
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['imported']).to eq(1)
      expect(body['skipped']).to eq(1)
      expect(body['errors'].size).to eq(1)
    end
  end

  describe 'a wholly rejected batch' do
    it 'returns 422 when every question is invalid' do
      import([ImportPayloads.multiple.merge(question_text: '')])
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).not_to be_empty
    end
  end
end
