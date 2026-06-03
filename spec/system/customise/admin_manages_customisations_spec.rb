# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for customisation admin flows.
# Non-interactive tests have been converted to spec/requests/customise_controller_spec.rb.
RSpec.describe 'Admin manages customisations', :default_creates, :js, type: :system do
  let(:available_customisation) { create(:dashboard_customisation, purchasable: true) }

  before { sign_in super_admin }

  context 'when viewing the customisation index' do
    let(:sticky_customisation) { create(:dashboard_customisation, sticky: true, purchasable: true) }

    before do
      available_customisation
      sticky_customisation
      visit customisations_path
    end

    it 'allows navigating to edit a customisation' do
      first('.card').click_link('Edit')
      expect(page).to have_current_path(edit_customisation_path(sticky_customisation))
    end
  end
end
