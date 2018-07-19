# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :user
  belongs_to :classroom
  has_many :asked_questions
  has_many :questions, through: :asked_questions
  has_one :subject, through: :classroom
  attr_accessor :picked_topic, :picked_subject
end
