# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DEBUG skin equip', :default_creates, :js, type: :system do
  let(:student) { create(:user, school:, challenge_points: 500) }

  before do
    setup_subject_database
    Customisation::SeedCosmetics.call(backfill: false)
    sign_in student
    visit(show_available_customisations_path)
  end

  it 'updates body[data-skin] after equipping a skin' do
    expect(find('body')['data-skin']).to eq('arcade')

    kawaii = Customisation.skin.find_by(value: 'kawaii')
    within(".tjs-skin-card[data-skin='kawaii']") do
      find("form[action='#{equip_customisation_path(kawaii)}'] input.equip-btn").click
    end

    # After the (turbo:false) full reload the body should carry the new skin.
    expect(page).to have_css('body[data-skin="kawaii"]')
    puts "BODY data-skin after equip: #{find('body')['data-skin']}"
    puts "BODY style after equip: #{find('body')['style']}"
    puts "Equipped skin in DB: #{student.reload.equipped_value(:skin)}"
  end
end
