# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customisation::BuyCustomisation, :default_creates do
  let(:student) { create(:student, school: school, challenge_points: 10) }
  let(:customisation) { create(:dashboard_customisation, cost: 5) }
  let(:old_customisation) { create(:dashboard_customisation, cost: 2) }

  before do
    create(:customisation_unlock, customisation: old_customisation, user: student)
  end

  context "when buying a new dashboard style" do
    it "creates a customisation unlock" do
      expect { described_class.call(student, customisation) }.to change(CustomisationUnlock, :count).by(1)
    end

    it "deducts the correct number of challenge points" do
      expect { described_class.call(student, customisation) }.to change { student.reload.challenge_points }.by(-5)
    end

    context "after purchase" do
      before { described_class.call(student, customisation) }

      it "sets the new customisation as active" do
        expect(ActiveCustomisation.where(customisation: customisation)).not_to be_empty
      end

      it "deactivates the old customisation" do
        expect(ActiveCustomisation.where(customisation: old_customisation)).to be_empty
      end
    end
  end

  context "when buying a leaderboard icon" do
    let(:customisation) { create(:customisation, cost: 5, customisation_type: "leaderboard_icon") }

    it "creates a customisation unlock" do
      expect { described_class.call(student, customisation) }.to change(CustomisationUnlock, :count).by(1)
    end

    context "after purchase" do
      before { described_class.call(student, customisation) }

      it "sets the new icon as active" do
        expect(ActiveCustomisation.where(customisation: customisation)).not_to be_empty
      end

      it "deactivates the old icon" do
        expect(ActiveCustomisation.where(customisation: old_customisation)).to be_empty
      end
    end
  end

  context "when the student has no existing customisation" do
    before { CustomisationUnlock.destroy_all }

    it "creates a customisation unlock" do
      expect { described_class.call(student, customisation) }.to change(CustomisationUnlock, :count).by(1)
    end
  end

  context "when the student does not have enough points" do
    let(:student) { create(:student, school: school, challenge_points: 3) }

    it "returns an insufficient points error" do
      expect(described_class.call(student, customisation).errors).to eq("You do not have enough points")
    end

    it "does not create a customisation unlock" do
      expect { described_class.call(student, customisation) }.not_to change(CustomisationUnlock, :count)
    end
  end

  context "when buying a previously purchased customisation" do
    before do
      create(:customisation_unlock, customisation: customisation, user: student)
    end

    it "does not deduct any points" do
      expect { described_class.call(student, customisation) }.not_to change { student.reload.challenge_points }
    end

    context "after re-activating" do
      before { described_class.call(student, customisation) }

      it "sets the customisation as active" do
        expect(ActiveCustomisation.where(customisation: customisation)).not_to be_empty
      end

      it "deactivates the previously active customisation" do
        expect(ActiveCustomisation.where(customisation: old_customisation)).to be_empty
      end
    end
  end
end
