# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Progression do
  describe '.level_for' do
    it 'starts everyone at level 1 with no xp' do
      expect(described_class.level_for(0)).to eq(1)
    end

    it 'treats the band below the first threshold as level 1' do
      expect(described_class.level_for(219)).to eq(1)
    end

    it 'reaches level 2 at 220 xp' do
      expect(described_class.level_for(220)).to eq(2)
    end

    it 'follows a quadratic curve (level 3 at 880, level 4 at 1980)' do
      expect(described_class.level_for(880)).to eq(3)
      expect(described_class.level_for(1980)).to eq(4)
    end

    it 'never drops below level 1 for negative or nil-ish xp' do
      expect(described_class.level_for(-50)).to eq(1)
    end

    it 'reaches level 10 at roughly ten hours of quizzing (~18k xp)' do
      # ~1800 answers at 10 xp each; the curve crosses level 10 within that band.
      expect(described_class.level_for(18_000)).to eq(10)
    end

    it 'is the inverse of .xp_for_level' do
      (1..6).each do |level|
        expect(described_class.level_for(described_class.xp_for_level(level))).to eq(level)
      end
    end
  end

  describe '.band_width' do
    it 'widens as levels climb (later levels cost much more)' do
      expect(described_class.band_width(1)).to eq(220)   # level 1 -> 2
      expect(described_class.band_width(2)).to eq(660)   # level 2 -> 3
      expect(described_class.band_width(9)).to eq(3740)  # level 9 -> 10
    end
  end

  describe '.xp_into_level' do
    it 'is the xp earned above the current level floor' do
      expect(described_class.xp_into_level(330)).to eq(110) # 330 - level-2 floor (220)
    end

    it 'is zero exactly on a level boundary and never negative' do
      expect(described_class.xp_into_level(220)).to eq(0)
      expect(described_class.xp_into_level(-5)).to eq(0)
    end
  end

  describe '.progress_percent' do
    it 'is 0 at a level floor and 50 halfway through the band' do
      expect(described_class.progress_percent(220)).to eq(0)   # start of level 2
      expect(described_class.progress_percent(550)).to eq(50)  # 330 into a 660-wide band
    end
  end
end
