class School < ApplicationRecord
  has_many :users
  validates :clientID, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_wonde(client_school)
    school = where(clientID: client_school.id).first_or_create
    school.name = client_school.name
    school.save
    school
  end
end
