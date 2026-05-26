# frozen_string_literal: true

class Homework < ApplicationRecord
  belongs_to :classroom
  belongs_to :topic
  belongs_to :lesson, optional: true

  has_many :homework_progresses, dependent: :destroy
  has_many :users, through: :classroom

  validates :due_date, presence: true
  validates :topic, presence: true
  validates :required, presence: true
  validate :due_date_cannot_be_in_the_past

  after_create :create_homework_progresses

  private

  def due_date_cannot_be_in_the_past
    errors.add(:due_date, "can't be in the past") if due_date.present? && due_date.past?
  end

  def create_homework_progresses
    users.where(role: :student).find_each do |u|
      homework_progresses.create(user: u, progress: 0, completed: false)
    end
  end
end
