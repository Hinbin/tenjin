class ActiveCustomisation < ApplicationRecord
  belongs_to :customisation
  belongs_to :user

  validates :user, uniqueness: { scope: [:customisation] }
end
