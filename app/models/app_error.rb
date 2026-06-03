# frozen_string_literal: true

class AppError < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :admin, optional: true

  validates :exception_class, presence: true
  validates :environment, presence: true
end
