class School < ApplicationRecord
  has_many :users
  has_many :subject_maps
  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_wonde(client_school)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.save
    school
  end
end
