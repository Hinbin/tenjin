# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::SetMode, :default_creates do
  before { Customisation::SeedCosmetics.call(backfill: false) }

  let(:light_mode) { Customisation.light_mode.first }

  def own_light_mode
    create(:customisation_unlock, customisation: light_mode, user: student)
  end

  it 'always allows switching to dark mode' do
    student.update!(dark_mode: false)
    result = described_class.call(student, true)
    expect(result.success?).to be(true)
    expect(student.reload.dark_mode).to be(true)
  end

  it 'refuses to switch to light mode while the perk is locked' do
    result = described_class.call(student, false)
    expect(result.success?).to be(false)
    expect(result.errors).to match(/locked/i)
    expect(student.reload.dark_mode).to be(true)
  end

  it 'switches to light mode once the perk is owned' do
    own_light_mode
    result = described_class.call(student, false)
    expect(result.success?).to be(true)
    expect(student.reload.dark_mode).to be(false)
  end
end
