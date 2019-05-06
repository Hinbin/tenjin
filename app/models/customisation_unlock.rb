class CustomisationUnlock < ApplicationRecord
  belongs_to :customisation
  belongs_to :user
end
