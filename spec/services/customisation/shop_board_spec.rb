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

  it 'groups all seven equip slots in order' do
    expect(board.categories.map(&:type)).to eq(
      %w[skin palette avatar nameplate name_effect answer_effect streak_aura]
    )
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
end
