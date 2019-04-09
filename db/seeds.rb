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

Multiplier.create([ {score: 0, multiplier: 1}, {score: 4, multiplier: 2}, {score: 7, multiplier: 4}, {score: 10, multiplier: 10} ] )

Customisation.create([ 
  {customisation_type: 0, cost: 10, name: 'Race Red', value: 'red'},
  {customisation_type: 0, cost: 10, name: 'Climber Orange', value: 'orange'},
  {customisation_type: 0, cost: 10, name: 'Ferrari Dark Red', value: 'darkred'},
  {customisation_type: 0, cost: 10, name: 'Hiking Dark Blue', value: 'darkblue'},
  {customisation_type: 0, cost: 10, name: 'Football Dark Green', value: 'darkgreen'},
  {customisation_type: 0, cost: 10, name: 'Music Yellow', value: 'yellow'}  
])

case Rails.env
  when "development"
    Admin.create(email: 'n.houlton@grange.outwood.com', password: 'password', password_confirmation: 'password', role: 'super')
    subject = Subject.where(name:'Computer Science').first
    DefaultSubjectMap.create(name: 'Sociology', subject: subject)
end


