# frozen_string_literal: true

class Topic < ApplicationRecord
  belongs_to :subject
  has_many :questions

  validates :name, presence: true
end
