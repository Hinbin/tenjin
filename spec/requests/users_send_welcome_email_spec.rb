# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /users/:id/send_welcome_email", :default_creates do
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html"} }

  before { sign_in super_admin }

  it "enqueues the setup email to the user" do
    expect {
      post send_welcome_email_user_path(school_admin), headers: turbo_headers
    }.to have_enqueued_mail(UserMailer, :setup_email).with(params: {user: school_admin}, args: [])
  end

  it "sends reset password instructions" do
    expect {
      post send_welcome_email_user_path(school_admin), headers: turbo_headers
    }.to change { school_admin.reload.reset_password_token }
  end
end
