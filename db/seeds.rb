# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

CSV.foreach('db/CSV Output - subject_export.csv', headers: true) do |row|
  Subject.create!(row.to_hash)
end

CSV.foreach('db/CSV Output - unit_export.csv', headers: true) do |row|
  Topic.create!(row.to_hash)
end

CSV.foreach('db/CSV Output - question_export.csv', headers: true) do |row|
  Question.create!(row.to_hash)
end

CSV.foreach('db/CSV Output - answer_export.csv', headers: true) do |row|
  Answer.create!(row.to_hash)
end

School.create([{ name: 'Outwood Grange' }, [{ name: 'Outwood Academy Adwick' }]])

Classroom.create([{ name: '9B/Cs1', subject_id: 1, school_id: 1 }])
Classroom.create([{ name: '9B/Hi2', subject_id: 2, school_id: 1 }])
Classroom.create([{ name: '9A/Cs1', subject_id: 1, school_id: 2 }])

User.create!([
  { email: 't.account@grange.outwood.com', password: 'Outwood01', password_confirmation: 'Outwood01', school_id: 1 },
  { email: 'a.nother@adwick.outwood.com', password: 'Outwood01', password_confirmation: 'Outwood01', school_id: 2 },
  { email: 's.udenim@grange.outwood.com', password: 'Outwood01', password_confirmation: 'Outwood01', school_id: 1 }
])

Enrollment.create!([
  { user_id: 1, classroom_id: 1, score: 0 },
  { user_id: 2, classroom_id: 3, score: 0 },
  { user_id: 3, classroom_id: 1, score: 0 },
  { user_id: 1, classroom_id: 2, score: 0 }
])
