# frozen_string_literal: true

class PagesController < HighVoltage::PagesController
  skip_after_action :verify_authorized
end
