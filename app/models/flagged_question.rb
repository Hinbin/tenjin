# frozen_string_literal: true

class FlaggedQuestion < ApplicationRecord
  belongs_to :user
  belongs_to :question
end
