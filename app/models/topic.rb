# frozen_string_literal: true

class Topic < ApplicationRecord
  belongs_to :subject
  has_many :questions
  has_many :lessons

  validates :name, presence: true
end
