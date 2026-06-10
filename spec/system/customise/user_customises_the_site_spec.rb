# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User customises the site", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  it "navigates from the shop dropdown to the styles page" do
    visit(dashboard_path)
    find("a", text: "Shop").click
    find("a", text: "Styles").click
    expect(page).to have_current_path(show_available_customisations_path)
  end

  describe "available dashboard styles" do
    let!(:dashboard_customisation) { create(:dashboard_customisation, cost: 6) }
    let!(:second_customisation) { create(:dashboard_customisation, cost: 4) }
    let(:student) { create(:student, school: school, challenge_points: 10) }

    before do
      visit(show_available_customisations_path)
    end

    it "lists available customisations and their prices" do
      expect(page).to have_content(dashboard_customisation.name.upcase)
        .and have_css("#cost", text: dashboard_customisation.cost)
    end

    context "when not all customisations are purchasable" do
      let!(:dashboard_customisation_unavailable) { create(:dashboard_customisation, cost: 6, purchasable: false) }

      it "hides unavailable customisations" do
        expect(page).to have_content(dashboard_customisation.name.upcase)
          .and have_no_content(dashboard_customisation_unavailable.name.upcase)
      end
    end

    context "after buying a customisation" do
      before do
        within("form[action='#{buy_customisation_path(dashboard_customisation)}']") do
          click_button "Buy"
        end
        expect(page).to have_current_path(dashboard_path)
      end

      context "when the student has enough points" do
        it "applies the style and deducts the cost" do
          expect(page).to have_css(".heading-divider[style*=#{dashboard_customisation.value}]")
            .and have_css("#challenge-points", text: (student.challenge_points - dashboard_customisation.cost).to_s)
        end
      end

      context "when the student does not have enough points" do
        let!(:dashboard_customisation) { create(:dashboard_customisation, cost: 20) }

        it "notifies them" do
          expect(page).to have_css(".alert", text: "You do not have enough points")
        end
      end

      context "when returning to the store" do
        before { visit(show_available_customisations_path) }

        it "shows the purchased customisation in a separate section" do
          expect(page).to have_content(second_customisation.name.upcase)

          within("section.purchased-styles") do
            expect(page).to have_content(dashboard_customisation.name.upcase)
              .and have_no_content(second_customisation.name.upcase)
          end
        end

        it "shows Switch instead of Buy" do
          expect(page).to have_css("input[value='Switch']")
        end

        it "allows switching back at no cost after buying another" do
          expected_points = student.challenge_points - dashboard_customisation.cost - second_customisation.cost

          within("form[action='#{buy_customisation_path(second_customisation)}']") do
            click_button "Buy"
          end
          expect(page).to have_current_path(dashboard_path)
          visit(show_available_customisations_path)
          within("form[action='#{buy_customisation_path(dashboard_customisation)}']") do
            click_button "Switch"
          end
          expect(page).to have_current_path(dashboard_path)
          expect(page).to have_css("#challenge-points", text: expected_points.to_s)
        end
      end
    end
  end

  describe "leaderboard icons" do
    let!(:icon_customisation) do
      create(:customisation, customisation_type: "leaderboard_icon", value: "black,star", cost: 10)
    end
    let(:student) { create(:student, school: school, challenge_points: 1000) }

    before do
      visit(show_available_customisations_path)
    end

    it "lists available icons with a buy button" do
      expect(page).to have_content(icon_customisation.name)
        .and have_button("Buy")
    end

    context "when an icon is not purchasable" do
      let!(:unpurchasable_icon) do
        create(:customisation, customisation_type: "leaderboard_icon", cost: 10, purchasable: false)
      end

      before { visit(show_available_customisations_path) }

      it "hides it" do
        expect(page).to have_no_content(unpurchasable_icon.name.upcase)
      end
    end

    context "when the student has a topic score" do
      let!(:topic_score) { create(:topic_score, user: student, topic: topic) }

      before { visit(show_available_customisations_path) }

      it "shows the icon on the leaderboard after buying" do
        within("form[action='#{buy_customisation_path(icon_customisation)}']") do
          click_button "Buy"
        end
        expect(page).to have_current_path(dashboard_path)
        visit(leaderboard_path(quiz_subject.name))
        expect(page).to have_css("td i.fa-star", style: "color: black;")
      end
    end
  end
end
