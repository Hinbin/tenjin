# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User customises the site', type: :system, js: true, default_creates: true do
  before do
    setup_subject_database
    sign_in student
  end

  context 'when visiting the customisation page from the navbar' do
    it 'visits from the customise link' do
      visit(dashboard_path)
      find('a', text: 'Customise').click
      find('a', text: 'Styles').click
      expect(page).to have_current_path(customise_path)
    end

    it 'visits from the challenge star' do
      visit(dashboard_path)
      find('i.fa-star').click
      expect(page).to have_current_path(customise_path)
    end

    it 'visits from the number of points' do
      visit(dashboard_path)
      find('#challenge-points').click
      expect(page).to have_current_path(customise_path)
    end
  end

  context 'when looking at available dashboard styles' do
    let(:dashboard_customisation) { create(:customisation, customisation_type: 'dashboard_style', cost: 6) }
    let(:dashboard_customisation_expensive) { create(:customisation, customisation_type: 'dashboard_style', cost: 20) }
    let(:second_customisation) { create(:customisation, customisation_type: 'dashboard_style', cost: 2) }
    let(:student) { create(:user, school: school, challenge_points: 10) }

    before do
      dashboard_customisation
      visit(customise_path)
    end

    it 'shows available dashboard customisations' do
      expect(page).to have_content(dashboard_customisation.name.upcase)
    end

    it 'allows you to buy a dashbord style' do
      find('button#buy-dashboard-' + dashboard_customisation.value).click
      expect(page).to have_css('section#homework-' + dashboard_customisation.value)
    end

    it 'deducts the required amount of challenge points' do
      find('button#buy-dashboard-' + dashboard_customisation.value).click
      expect { student.reload }.to change(student, :challenge_points).by(-dashboard_customisation.cost)
    end

    it 'gives a notice if you do not have the required number of points' do
      dashboard_customisation_expensive
      visit(customise_path)
      find('button#buy-dashboard-' + dashboard_customisation_expensive.value).click
      expect(page).to have_css('.alert', text: 'You do not have enough points')
    end

    it 'shows the cost of the customisation' do
      expect(page).to have_css('#cost', text: dashboard_customisation.cost)
    end

    context 'when repurchasing a customisation already unlocked' do
      before do
        find('button#buy-dashboard-' + dashboard_customisation.value).click
        second_customisation
        visit(customise_path)
        find('button#buy-dashboard-' + second_customisation.value).click
        student.reload
      end

      it 'allows you to buy a previously bought customisation at no cost' do
        visit(customise_path)

        find('button#buy-dashboard-' + dashboard_customisation.value).click
        expect { student.reload }.to change(student, :challenge_points).by(0)
      end

      it 'sets the price of unlocked customisations to zero' do
        visit(customise_path)
        expect(page).to have_css('#cost', text: '0')
      end
    end
  end

  context 'when purchasing a leaderboard icon' do
    let(:icon_customisation) do
      create(:customisation, customisation_type:
      'leaderboard_icon', value: 'black,star', cost: 10)
    end

    before do
      icon_customisation
      student.update_attribute(:challenge_points, 1000)
      visit(customise_path)
    end

    it 'shows what icons are available to purchase' do
      expect(page).to have_content(icon_customisation.name)
    end

    it 'allows you to buy an icon' do
      expect(page).to have_css("[data-value='#{icon_customisation.value}']")
    end

    it 'shows the icon on the leaderboard' do
      create(:topic_score, user: student, topic: topic)
      find("[data-value='#{icon_customisation.value}']").click
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: black;')
    end
  end
end
