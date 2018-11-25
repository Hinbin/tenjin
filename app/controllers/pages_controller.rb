# app/controllers/pages_controller.rb
class PagesController < HighVoltage::PagesController
  skip_after_action :verify_authorized
end
