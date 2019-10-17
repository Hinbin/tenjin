# frozen_string_literal: true

class AskedQuestion < ApplicationRecord
  belongs_to :question
  belongs_to :quiz
end
