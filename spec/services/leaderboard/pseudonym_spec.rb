# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Leaderboard::Pseudonym do
  describe '.generate' do
    it 'is deterministic for the same seed' do
      first = described_class.generate(12_345)
      expect(described_class.generate(12_345)).to eq(first)
    end

    it 'produces a two-word "Plant Figure" name from the word lists' do
      plant, figure = described_class.generate(98_765).split(' ', 2)
      expect(described_class::PLANTS).to include(plant)
      expect(described_class::MYTHICAL).to include(figure)
    end

    it 'varies across different seeds' do
      names = (1..50).map { |seed| described_class.generate(seed) }
      expect(names.uniq.length).to be > 1
    end
  end
end
