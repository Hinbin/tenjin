# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User customises the site', :default_creates, :js, type: :system do
  before do
    setup_subject_database
    Customisation::SeedCosmetics.call(backfill: false)
    sign_in student
  end

  context 'when visiting the reward shop from the navbar' do
    it 'visits from the shop link' do
      visit(dashboard_path)
      find('a', text: 'Shop').click
      expect(page).to have_current_path(show_available_customisations_path)
    end

    it 'visits from the challenge star' do
      visit(dashboard_path)
      find('a.tj-navbar__points').click
      expect(page).to have_current_path(show_available_customisations_path)
    end
  end

  context 'when looking at the reward shop' do
    let(:student) { create(:user, school:, challenge_points: 500) }

    before { visit(show_available_customisations_path) }

    it 'shows the skins section with a skin card' do
      within('section[data-cat="skin"]') do
        expect(page).to have_css('.tjs-skin-card[data-skin="arcade"]')
        expect(page).to have_css('.tjs-skin-card__tagline')
      end
    end

    it 'groups a skin\'s palettes under it' do
      within('.tjs-skin-card[data-skin="arcade"]') do
        expect(page).to have_css('.tjs-palette-chip', minimum: 2)
      end
    end

    it 'lets me buy a paid cosmetic and deducts the points' do
      gem = Customisation.avatar.find_by(value: 'gem')
      find("form[action='#{buy_customisation_path(gem)}'] input.buy-btn").click
      expect(page).to have_css('.tjs-flash', text: 'Congratulations!')
      expect(page).to have_css('#challenge-points', exact_text: student.challenge_points - gem.cost)
    end

    it 'auto-equips a bought cosmetic so it shows as equipped' do
      gem = Customisation.avatar.find_by(value: 'gem')
      find("form[action='#{buy_customisation_path(gem)}'] input.buy-btn").click
      expect(page).to have_css(".tjs-shop-item[data-value='gem'].is-equipped")
    end

    it 'warns when I cannot afford an item' do
      student.update!(challenge_points: 0)
      visit(show_available_customisations_path)
      crown = Customisation.avatar.find_by(value: 'crown')
      expect(page).to have_css("form[action='#{buy_customisation_path(crown)}'] input.buy-btn[disabled]")
    end
  end
end
