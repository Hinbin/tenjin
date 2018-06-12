require 'csv'

namespace :import do 
  desc "Import all data from CSV"

  task all: :environment do 
    CSV.foreach('db/CSV Output - unit_export.csv', :headers => true) do |row|
      Topic.create!(row.to_hash)
    end

    CSV.foreach('db/CSV Output - question_export.csv', :headers => true) do |row|
      Question.create!(row.to_hash)
    end

    CSV.foreach('db/CSV Output - answer_export.csv', :headers => true) do |row|
      Answer.create!(row.to_hash)
    end

  end

end