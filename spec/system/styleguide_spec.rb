# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Skin Styleguide', :js, type: :system do
  before { visit '/styleguide' }

  it 'renders the page with the default arcade skin' do
    body = find('body')
    expect(body['data-skin']).to eq('arcade')
    expect(body['data-mode']).to eq('dark')
    expect(page).to have_css('.tjs-card')
    expect(page).to have_css('.tjs-btn--primary')
  end

  describe 'skin switching' do
    %w[arcade kawaii minimal famicom zen].each do |skin|
      it "switches to #{skin} skin and updates body[data-skin]" do
        click_button skin.capitalize
        body = find('body')
        expect(body['data-skin']).to eq(skin)
      end
    end
  end

  describe 'palette switching' do
    it 'switches to palette 1 and updates body[data-palette]' do
      click_button 'P1'
      body = find('body')
      expect(body['data-palette']).to eq('1')
    end
  end

  describe 'mode switching' do
    it 'switches to light mode and updates body[data-mode]' do
      click_button 'Light'
      body = find('body')
      expect(body['data-mode']).to eq('light')
    end

    it 'switches back to dark mode' do
      click_button 'Light'
      click_button 'Dark'
      body = find('body')
      expect(body['data-mode']).to eq('dark')
    end
  end

  describe 'reset' do
    it 'reverts the live preview to the server-rendered theme' do
      click_button 'Kawaii'
      expect(find('body')['data-skin']).to eq('kawaii')
      click_button 'Reset'
      # Reset restores the server-rendered theme in place (no reload needed).
      # Server-rendered default is arcade (no user logged in).
      expect(find('body')['data-skin']).to eq('arcade')
    end
  end

  it 'renders all atom sections' do
    # arcade skin applies text-transform:uppercase — match via regex to be case-insensitive
    %w[Logo Buttons Cards Avatars Pills Glyphs].each do |label|
      expect(page).to have_text(/#{label}/i)
    end
    expect(page).to have_text(/Subject.tiles/i)
    expect(page).to have_text(/Stat.chips/i)
    expect(page).to have_text(/Section.headers/i)
    expect(page).to have_text(/Progress.bars/i)
  end

  it 'renders the backdrop partial' do
    # .tjs-backdrop container is always in DOM; only its layer children are display:none per skin
    expect(page).to have_css('.tjs-backdrop', visible: :any)
  end

  describe 'zen skin' do
    before { click_button 'Zen' }

    it 'applies zen skin data-skin attribute' do
      expect(find('body')['data-skin']).to eq('zen')
    end

    it 'renders the petal backdrop elements' do
      # petals container is shown (display:block) when zen skin is active
      expect(page).to have_css('.tjs-backdrop-petals')
    end
  end

  describe 'prefers-reduced-motion safety' do
    it 'never hides content via animation base state' do
      # Entrance helper classes must be visible even with animations
      # (base state is opacity:1 / transform:none)
      expect(all('.tjs-slideup, .tjs-pop')).to all(be_visible)
    end
  end
end
