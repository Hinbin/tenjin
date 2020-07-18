# frozen_string_literal: true

class Classroom < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments
  has_many :homeworks

  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_wonde(school, classroom)
    create_classroom(classroom, school)
  end

  def self.create_classroom(classroom, school)
    c = Classroom.where(client_id: classroom.id).first_or_initialize
    c.client_id = classroom.id
    c.name = classroom.name
    c.description = classroom.description
    c.code = classroom.code
    c.school_id = school.id
    c.disabled = false
    c.save
    c
  end

  def homework_counts
    h_count = HomeworkProgress.arel_table[:id].count

    topic_name = Topic.arel_table[:name]
    Homework.select(:id, h_count, homework_count_completed.sum.as('completed_count'), :due_date, :topic_id, topic_name)
            .joins(:homework_progresses, :topic)
            .group(:id, topic_name)
            .where(classroom: self)
  end

  def homework_count_completed
    h_count_completed = Arel::Nodes::Case.new HomeworkProgress.arel_table[:completed]
    h_count_completed.when(true).then(1).else(0)
  end
end
