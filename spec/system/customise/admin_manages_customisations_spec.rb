# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin manages customisations', type: :system, js: true, default_creates: true do
  let(:available_customisation) { create(:dashboard_customisation, purchasable: true) }
  let(:new_name) { FFaker::Lorem.word }

  before do
    sign_in super_admin
  end

  def fill_in_customisation_form
    fill_in('Name', with: new_name)
    fill_in('Value', with: 'blue')
    fill_in('Cost', with: '200')
  end

  it 'can be accessed from the super admin navbar' do
    visit schools_path
    click_link('Customisations')
    expect(page).to have_css('.available-customisations')
  end

  it 'cannot be accessed from the school group admin navbar' do
    sign_out super_admin
    sign_in school_group_admin
    visit schools_path
    expect(page).to have_no_link('Customisations')
  end

  context 'when viewing the customisation index' do
    let(:unavailable_customisation) { create(:dashboard_customisation, purchasable: false) }
    let(:retired_customisation) { create(:dashboard_customisation, retired: true) }
    let(:sticky_customisation) { create(:dashboard_customisation, sticky: true, purchasable: true) }

    before do
      available_customisation
      unavailable_customisation
      retired_customisation
      sticky_customisation
      visit customisations_path
    end

    it 'shows currently available customisations' do
      expect(page).to have_css('section.available-customisations .card',
                               text: available_customisation.name.upcase)
    end

    it 'puts stickied customisations on top' do
      expect(page).to have_css('section.available-customisations .card:nth-of-type(1)',
                               text: sticky_customisation.name.upcase)
    end

    it 'marks stickied customisations' do
      expect(page).to have_css('section.available-customisations .card:nth-of-type(1)', text: 'STICKIED')
    end

    it 'puts unavailable customisations at the bottom' do
      expect(page).to have_css('section.available-customisations .card:nth-of-type(3)',
                               text: unavailable_customisation.name.upcase)
    end

    it 'marks unavailable customisations' do
      expect(page).to have_css('section.available-customisations .card:nth-of-type(3)', text: 'UNAVAILABLE')
    end

    it 'shows retired customisations in their own section' do
      expect(page).to have_css('section.retired-customisations .card', text: retired_customisation.name.upcase)
    end

    it 'allows you to edit dashboard_style customisations' do
      first('.card').click_link('Edit')
      expect(page).to have_current_path(edit_customisation_path(sticky_customisation))
    end
  end

  context 'when editing a dashboard style' do
    before do
      visit(edit_customisation_path(available_customisation))
    end

    it 'updates the name' do
      new_name = FFaker::Lorem.word
      fill_in('Name', with: new_name)
      click_button('Update Customisation')
      expect(page).to have_content(new_name.upcase)
    end

    it 'updates the value' do
      fill_in('Value', with: 'blue')
      click_button('Update Customisation')
      expect(page).to have_css("hr[style*='blue']")
    end

    it 'updates the picture' do
      attach_file('Image', "#{Rails.root}/spec/fixtures/files/computer-science.jpg")
      click_button('Update Customisation')
      expect(page).to have_css('div [style*="computer-science.jpg"]')
    end

    it 'updates if it is sticky' do
      check('Sticky')
      click_button('Update Customisation')
      expect(page).to have_content('Stickied'.upcase)
    end

    it 'updates if it is purchsable' do
      uncheck('Purchasable')
      click_button('Update Customisation')
      expect(page).to have_content('Unavailable'.upcase)
    end
  end

  context 'when creating a dashboard style' do

    before do
      visit new_customisation_path
    end

    it 'creates it' do
      fill_in_customisation_form
      attach_file('Image', "#{Rails.root}/spec/fixtures/files/game-pieces.jpg")
      click_button('Create Customisation')
      expect(page).to have_content(new_name.upcase)
    end
  end

  context 'when creating a leaderboard icon' do
    before do
      visit new_customisation_path
    end

    it 'creates leaderboard_icon customisations' do
      select 'Leaderboard icon', from: 'customisation_customisation_type'
      fill_in_customisation_form
      fill_in('Value', with: 'blue,cheese')
      click_button('Create Customisation')
      expect(page).to have_content(new_name)
    end
  end

  it 'prevents me from accessing customisations as a user' do
    sign_out super_admin
    sign_in school_admin
    visit customisations_path
    expect(page).to have_current_path(new_admin_session_path)
  end

  it 'prevents me from accessing customisations unless I am a super admin' do
    sign_out super_admin
    sign_in school_group_admin
    visit customisations_path
    expect(page).to have_current_path(root_path)
  end
end
