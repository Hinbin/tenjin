# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::ShopBoard, :default_creates do
  before { Customisation::SeedCosmetics.call(backfill: false) }

  let(:board) { described_class.call(student) }

  def avatar_item(value)
    board.categories.find { |c| c.type == 'avatar' }.items.find { |i| i.value == value }
  end

  it 'exposes the wallet balance' do
    student.update!(challenge_points: 250)
    expect(board.wallet).to eq(250)
  end

  it 'groups the equip slots in order, with palettes nested under skins' do
    expect(board.categories.map(&:type)).to eq(
      %w[skin avatar nameplate name_effect answer_effect streak_aura]
    )
  end

  it 'nests each skin\'s palettes and tagline on the skin item' do
    arcade = board.categories.find { |c| c.type == 'skin' }.items.find { |i| i.value == 'arcade' }
    expect(arcade.tagline).to be_present
    expect(arcade.palettes.map(&:value)).to include('arcade:0', 'arcade:1')
    expect(arcade.palettes).to all(have_attributes(customisation: an_instance_of(Customisation)))
  end

  it 'marks free items as owned and buyable paid items as not owned' do
    expect(avatar_item('torii')).to have_attributes(owned: true, buyable?: false)
    expect(avatar_item('gem')).to have_attributes(owned: false, buyable?: true)
  end

  it 'reflects the equipped item per slot' do
    gem = Customisation.avatar.find_by(value: 'gem')
    create(:customisation_unlock, customisation: gem, user: student)
    Customisation::EquipCustomisation.call(student, gem)
    expect(avatar_item('gem').equipped).to be(true)
    expect(avatar_item('torii').equipped).to be(false)
  end

  it 'marks a gated item as locked rather than buyable' do
    expect(avatar_item('trophy')).to have_attributes(locked?: true, buyable?: false)
  end

  it 'carries the avatar glyph + token for previews' do
    expect(avatar_item('gem')).to have_attributes(glyph: 'gem', token: 'var(--n2)')
  end

  describe 'the light/dark mode status' do
    it 'reports dark and not-owned for a fresh student locked to dark' do
      expect(board.mode).to have_attributes(dark: true, owned: false, cost: 100)
      expect(board.mode.customisation).to be_a(Customisation)
    end

    it 'marks light mode as owned once the perk is unlocked' do
      create(:customisation_unlock, customisation: Customisation.light_mode.first, user: student)
      expect(board.mode.owned).to be(true)
    end

    it 'reflects the user\'s current mode' do
      student.update!(dark_mode: false)
      expect(board.mode.dark).to be(false)
    end

    it 'keeps the light-mode perk out of the equip-slot categories' do
      expect(board.categories.map(&:type)).not_to include('light_mode')
    end
  end
end
