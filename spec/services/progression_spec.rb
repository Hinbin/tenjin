# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Progression do
  describe '.level_for' do
    it 'starts everyone at level 1 with no xp' do
      expect(described_class.level_for(0)).to eq(1)
    end

    it 'treats the band below the first threshold as level 1' do
      expect(described_class.level_for(99)).to eq(1)
    end

    it 'reaches level 2 at 100 xp' do
      expect(described_class.level_for(100)).to eq(2)
    end

    it 'follows a quadratic curve (level 3 at 400, level 4 at 900)' do
      expect(described_class.level_for(400)).to eq(3)
      expect(described_class.level_for(900)).to eq(4)
    end

    it 'never drops below level 1 for negative or nil-ish xp' do
      expect(described_class.level_for(-50)).to eq(1)
    end

    it 'is the inverse of .xp_for_level' do
      (1..6).each do |level|
        expect(described_class.level_for(described_class.xp_for_level(level))).to eq(level)
      end
    end
  end
end
