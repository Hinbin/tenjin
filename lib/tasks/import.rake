require 'csv'

namespace :import do
  desc 'Import all data from CSV'

  task all: :environment do
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

    Classroom.create([{name: '9B/Cs1', subject_id: 1}])
    School.create([{name:'Outwood Grange'}, [{name:'Outwood Academy Adwick'}]])

    
  end
end

# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
