# frozen_string_literal: true

class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
    :recoverable, :rememberable, :validatable,
    authentication_keys: [:email]

  validates :role, presence: true

  enum :role, {super: 0, school_group: 1}
end
