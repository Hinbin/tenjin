# frozen_string_literal: true

class CustomisationUnlock < ApplicationRecord
  belongs_to :customisation
  belongs_to :user
end
