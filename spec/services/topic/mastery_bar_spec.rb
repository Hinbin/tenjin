# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Topic::MasteryBar do
  def bar(weekly: 0, all_time: 0, percentile: 0)
    described_class.call(weekly_score: weekly, all_time_score: all_time, percentile: percentile)
  end

  it 'returns 0 for a topic with no points and no standing' do
    expect(bar).to eq(0)
  end

  it 'fills the mastery half from combined weekly and all-time points' do
    # 60% weight, points capped at MASTERY_TARGET (500) -> full mastery half = 60.
    expect(bar(weekly: 250, all_time: 250)).to eq(60)
    expect(bar(all_time: 1_000)).to eq(60) # over target stays capped
  end

  it 'fills the peer half from the percentile' do
    # 40% weight: 100th percentile -> 40.
    expect(bar(percentile: 100)).to eq(40)
    expect(bar(percentile: 50)).to eq(20)
  end

  it 'blends both halves and reaches 100 only when maxed on both' do
    expect(bar(all_time: 500, percentile: 100)).to eq(100)
  end

  it 'clamps a percentile outside 0..100' do
    expect(bar(percentile: 250)).to eq(40)
  end
end
