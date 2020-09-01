# frozen_string_literal: true

class Homework < ApplicationRecord
  belongs_to :classroom
  belongs_to :topic
  belongs_to :lesson, optional: true

  has_many :homework_progresses, dependent: :destroy
  has_many :users, through: :classroom

  validates :due_date, presence: true
  validates :topic_id, presence: true
  validates :required, presence: true
  validate :due_date_cannot_be_in_the_past

  after_create :create_homework_progresses
  before_destroy :destroy_homework_progresses

  private

  def due_date_cannot_be_in_the_past
    errors.add(:due_date, "can't be in the past") if due_date.present? && due_date.past?
  end

  def create_homework_progresses
    users.where(role: 'student').each do |u|
      HomeworkProgress.create(user: u, homework: self, progress: 0, completed: false)
    end
  end

  def destroy_homework_progresses
    HomeworkProgress.where(homework: self).destroy_all
  end
end
