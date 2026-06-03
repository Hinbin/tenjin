# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::RefreshCustomisationsInStore, :default_creates do
  let(:retired_customisation) { create(:dashboard_customisation, cost: 5, retired: true) }

  context 'when refreshing customisations' do
    it 'ignores retires customisations' do
      retired_customisation
      described_class.new.call
      retired_customisation.reload
      expect(retired_customisation.purchasable).to eq(false)
    end

    it 'activates up to six customisations randomly' do
      create_list(:dashboard_customisation, 10)
      described_class.new.call
      expect(Customisation.where(purchasable: true).count).to eq(6)
    end

    it 'always picks sticky customisations' do
      create_list(:dashboard_customisation, 12)
      create_list(:dashboard_customisation, 5, sticky: true)
      described_class.new.call
      expect(Customisation.where(purchasable: true, sticky: true).count).to eq(5)
    end

    it 'activates both leaderboard_icons and dashboard_styles' do
      create_list(:customisation, 12, customisation_type: 'leaderboard_icon')
      create_list(:dashboard_customisation, 12)
      described_class.new.call
      expect(Customisation.where(purchasable: true, customisation_type: 'leaderboard_icon').count).to eq(6)
    end
  end
end
