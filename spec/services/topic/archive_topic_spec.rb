# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Topic::ArchiveTopic, :default_creates do
  let!(:active_challenge) { create(:challenge, topic:, end_date: 1.day.from_now) }
  let!(:expired_challenge) { create(:challenge, topic:, end_date: 1.day.ago) }

  it 'archives the topic and removes active challenges' do
    result = described_class.call(topic)

    expect(result).to be_success
    expect(topic.reload).not_to be_active
    expect(Challenge.exists?(active_challenge.id)).to be false
    expect(Challenge.exists?(expired_challenge.id)).to be true
  end
end
