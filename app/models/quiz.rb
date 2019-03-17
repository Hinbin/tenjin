# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :user
  belongs_to :subject
  belongs_to :topic, optional: true

  has_many :asked_questions
  has_many :questions, through: :asked_questions
  attr_accessor :picked_topic, :picked_subject
end
