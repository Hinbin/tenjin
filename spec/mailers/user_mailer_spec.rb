# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, :default_creates do
  describe "#setup_email" do
    subject(:mail) { described_class.with(user: school_admin, password: "abc123").setup_email }

    it "sends to the user" do
      expect(mail.to).to contain_exactly(school_admin.email)
    end

    it "uses the welcome subject" do
      expect(mail.subject).to eq("Welcome to Tenjin")
    end
  end
end
