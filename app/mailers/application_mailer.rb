# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'tenjin@outwood.com'
  layout 'mailer'
end
