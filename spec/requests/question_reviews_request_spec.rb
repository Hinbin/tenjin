# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'QuestionReviews', type: :request do
  let(:subject) { create(:subject) }
  let(:topic) { create(:topic, subject:) }
  let(:author) { create(:question_author, subject:) }
  let(:pending_question) do
    create(:question, topic:, review_status: :pending, active: false)
  end

  describe 'GET /question_reviews' do
    before { sign_in author }

    it 'lists pending questions in the authored subject' do
      pending_question
      get question_reviews_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(id="question-#{pending_question.id}"))
    end

    it 'omits approved questions' do
      approved = create(:question, topic:, review_status: :approved, active: true)
      get question_reviews_path

      expect(response.body).not_to include(%(id="question-#{approved.id}"))
    end
  end

  describe 'PATCH approve / reject' do
    before { sign_in author }

    it 'approves a pending question' do
      patch approve_question_review_path(pending_question)

      expect(pending_question.reload).to have_attributes(review_status: 'approved', active: true)
    end

    it 'rejects a pending question' do
      patch reject_question_review_path(pending_question)

      expect(pending_question.reload).to have_attributes(review_status: 'rejected', active: false)
    end

    it 'responds with a Turbo Stream that removes the reviewed item' do
      patch approve_question_review_path(pending_question), as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(target="question-#{pending_question.id}"))
      expect(response.body).to include('Question approved')
    end
  end

  describe 'PATCH approve_all' do
    before { sign_in author }

    it 'approves every pending question in the authored subject' do
      pending_question
      other = create(:question, topic:, review_status: :pending, active: false)

      patch approve_all_question_reviews_path

      expect(pending_question.reload).to have_attributes(review_status: 'approved', active: true)
      expect(other.reload).to have_attributes(review_status: 'approved', active: true)
      expect(response).to redirect_to(question_reviews_path)
    end

    it 'leaves pending questions in other subjects untouched' do
      pending_question
      foreign = create(:question, topic: create(:topic, subject: create(:subject)),
                                  review_status: :pending, active: false)

      patch approve_all_question_reviews_path

      expect(pending_question.reload.review_status).to eq('approved')
      expect(foreign.reload.review_status).to eq('pending')
    end
  end

  describe 'PATCH reject_all' do
    before { sign_in author }

    it 'rejects every pending question in the authored subject' do
      pending_question
      other = create(:question, topic:, review_status: :pending, active: false)

      patch reject_all_question_reviews_path

      expect(pending_question.reload).to have_attributes(review_status: 'rejected', active: false)
      expect(other.reload).to have_attributes(review_status: 'rejected', active: false)
      expect(response).to redirect_to(question_reviews_path)
    end

    it 'leaves pending questions in other subjects untouched' do
      pending_question
      foreign = create(:question, topic: create(:topic, subject: create(:subject)),
                                  review_status: :pending, active: false)

      patch reject_all_question_reviews_path

      expect(pending_question.reload.review_status).to eq('rejected')
      expect(foreign.reload.review_status).to eq('pending')
    end
  end

  describe 'authorization' do
    let(:other_author) { create(:question_author, subject: create(:subject)) }

    it 'forbids approving a question outside the authored subject' do
      sign_in other_author
      patch approve_question_review_path(pending_question)

      expect(pending_question.reload.review_status).to eq('pending')
    end

    it 'redirects a signed-out visitor' do
      patch approve_question_review_path(pending_question)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
