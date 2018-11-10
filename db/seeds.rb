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
