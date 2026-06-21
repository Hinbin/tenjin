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
      %w[skin scene motion avatar nameplate name_effect answer_effect streak_aura scene_fx]
    )
  end

  describe 'the skin-locked scene category' do
    let(:active_skin) { Theme::Selection.for(student).skin }
    let(:scenes) { board.categories.find { |c| c.type == 'scene' } }

    it 'offers only the active skin\'s scenes' do
      expected = Cosmetic::SceneCatalog.scenes_for(active_skin).map { |s| "#{active_skin}:#{s[:value]}" }
      expect(scenes.items.map(&:value)).to eq(expected)
    end

    it 'marks the free none default as equipped when no scene is chosen' do
      none = scenes.items.find { |i| i.value.end_with?(':none') }
      expect(none).to have_attributes(owned: true, equipped: true)
    end
  end

  describe 'the skin-locked ambient motion category' do
    let(:active_skin) { Theme::Selection.for(student).skin }
    let(:motions) { board.categories.find { |c| c.type == 'motion' } }

    it 'offers only the active skin\'s motions' do
      expected = Cosmetic::MotionCatalog.motions_for(active_skin).map { |m| "#{active_skin}:#{m[:value]}" }
      expect(motions.items.map(&:value)).to eq(expected)
    end

    it 'marks the free none default as equipped when no motion is chosen' do
      none = motions.items.find { |i| i.value.end_with?(':none') }
      expect(none).to have_attributes(owned: true, equipped: true)
    end
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

  describe 'when previewing an item (try-before-you-buy)' do
    let(:kawaii_skin) { Customisation.skin.find_by(value: 'kawaii') }
    let(:preview_board) { described_class.call(student, preview: kawaii_skin) }

    def skin_item(board, value)
      board.categories.find { |c| c.type == 'skin' }.items.find { |i| i.value == value }
    end

    it 'flags the previewed skin item' do
      expect(skin_item(preview_board, 'kawaii').previewing).to be(true)
      expect(skin_item(preview_board, 'arcade').previewing).to be(false)
    end

    it 'swaps the scene category to the previewed skin\'s scenes' do
      expected = Cosmetic::SceneCatalog.scenes_for('kawaii').map { |s| "kawaii:#{s[:value]}" }
      scenes = preview_board.categories.find { |c| c.type == 'scene' }
      expect(scenes.items.map(&:value)).to eq(expected)
    end

    it 'leaves everything unflagged when no preview is active' do
      expect(skin_item(board, 'kawaii').previewing).to be(false)
    end
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
