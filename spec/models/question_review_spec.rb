# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question, :default_creates do
  describe 'review workflow' do
    let(:pending_question) do
      create(:question, topic:, review_status: :pending, active: false)
    end

    it 'defaults new questions to pending' do
      expect(create(:question, topic:).review_status).to eq('pending')
    end

    it 'approving makes it active' do
      pending_question.approve!

      expect(pending_question).to have_attributes(review_status: 'approved', active: true)
    end

    it 'rejecting leaves it inactive' do
      pending_question.reject!

      expect(pending_question).to have_attributes(review_status: 'rejected', active: false)
    end
  end

  describe 'visibility to students' do
    let(:student_scope) { described_class.where(active: true, topic:) }

    it 'excludes pending (inactive) questions from the active scope students draw from' do
      pending = create(:question, topic:, review_status: :pending, active: false)

      expect(student_scope).not_to include(pending)
    end

    it 'includes a question once it is approved' do
      question = create(:question, topic:, review_status: :pending, active: false)

      expect { question.approve! }.to change { student_scope.exists?(question.id) }.from(false).to(true)
    end
  end
end
