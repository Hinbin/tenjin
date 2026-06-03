# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'submitting a customisation', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school, challenge_points: 100) }
  let(:customisation) { create(:customisation) }

  before do
    sign_in student
  end

  context 'when selecting a customisation type that does not exist' do
    subject do
      post buy_customisation_path(id: rand(200..300))
    end

    it { is_expected.to redirect_to(show_available_customisations_path) }
  end
end

RSpec.describe 'Admin manages customisations', :default_creates, type: :request do
  let(:available_customisation) { create(:dashboard_customisation, purchasable: true) }
  let(:new_name) { FFaker::Lorem.word }

  before { sign_in super_admin }

  it 'can be accessed from the super admin navbar' do
    get schools_path
    html = Capybara.string(response.body)
    expect(html).to have_link('Customisations', href: customisations_path)
  end

  it 'cannot be accessed from the school group admin navbar' do
    sign_in school_group_admin
    get schools_path
    html = Capybara.string(response.body)
    expect(html).to have_no_link('Customisations')
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
      get customisations_path
    end

    it 'shows currently available customisations' do
      html = Capybara.string(response.body)
      expect(html).to have_css('section.available-customisations .dashboard-style',
                               text: available_customisation.name)
    end

    it 'puts stickied customisations on top' do
      html = Capybara.string(response.body)
      dashboard_styles = html.all('section.available-customisations .dashboard-style')
      expect(dashboard_styles.first).to have_text(sticky_customisation.name)
    end

    it 'marks stickied customisations' do
      html = Capybara.string(response.body)
      dashboard_styles = html.all('section.available-customisations .dashboard-style')
      expect(dashboard_styles.first).to have_text('Stickied')
    end

    it 'puts unavailable customisations at the bottom' do
      html = Capybara.string(response.body)
      dashboard_styles = html.all('section.available-customisations .dashboard-style')
      expect(dashboard_styles.last).to have_text(unavailable_customisation.name)
    end

    it 'marks unavailable customisations' do
      html = Capybara.string(response.body)
      dashboard_styles = html.all('section.available-customisations .dashboard-style')
      expect(dashboard_styles.last).to have_text('Unavailable')
    end

    it 'shows retired customisations in their own section' do
      html = Capybara.string(response.body)
      expect(html).to have_css('section.retired-customisations .dashboard-style', text: retired_customisation.name)
    end

    it 'allows editing a customisation' do
      html = Capybara.string(response.body)
      expect(html).to have_link('Edit', href: edit_customisation_path(sticky_customisation))
    end
  end

  context 'when editing a dashboard style' do
    before { available_customisation }

    it 'updates the name' do
      patch customisation_path(available_customisation), params: { customisation: { name: new_name } }
      follow_redirect!
      expect(response.body).to include(new_name)
    end

    it 'updates the value' do
      patch customisation_path(available_customisation), params: { customisation: { value: 'blue' } }
      follow_redirect!
      html = Capybara.string(response.body)
      expect(html).to have_css("hr[style*='blue']")
    end

    it 'updates the picture' do
      patch customisation_path(available_customisation), params: {
        customisation: { image: fixture_file_upload('computer-science.jpg', 'image/jpeg') }
      }
      expect(available_customisation.reload.image).to be_attached
    end

    it 'updates if it is sticky' do
      patch customisation_path(available_customisation), params: { customisation: { sticky: true } }
      follow_redirect!
      expect(response.body).to include('Stickied')
    end

    it 'updates if it is purchasable' do
      patch customisation_path(available_customisation), params: { customisation: { purchasable: false } }
      follow_redirect!
      expect(response.body).to include('Unavailable')
    end
  end

  context 'when creating a dashboard style' do
    it 'creates it' do
      post customisations_path, params: {
        customisation: {
          name: new_name,
          value: 'blue',
          cost: 200,
          purchasable: false,
          retired: false,
          image: fixture_file_upload('game-pieces.jpg', 'image/jpeg')
        }
      }
      follow_redirect!
      expect(response.body).to include(new_name)
    end
  end

  context 'when creating a leaderboard icon' do
    it 'creates leaderboard_icon customisations' do
      post customisations_path, params: {
        customisation: {
          customisation_type: 'leaderboard_icon',
          name: new_name,
          value: 'blue,cheese',
          cost: 200,
          purchasable: false,
          retired: false
        }
      }
      follow_redirect!
      expect(response.body).to include(new_name)
    end
  end

  it 'prevents accessing customisations as a regular user' do
    sign_out super_admin
    sign_in student
    get customisations_path
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'prevents accessing customisations unless super admin' do
    sign_in school_group_admin
    get customisations_path
    expect(response).to redirect_to(root_path)
  end
end
