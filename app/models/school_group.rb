# frozen_string_literal: true

class SchoolGroup < ApplicationRecord
  validates :name, presence: true
end
