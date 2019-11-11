# frozen_string_literal: true

class Answer < ApplicationRecord
  belongs_to :question
  validates_presence_of :text
end
