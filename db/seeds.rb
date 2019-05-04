# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

def create_file_blob(data:, filename:, content_type:, metadata: nil)
  ActiveStorage::Blob.create_after_upload! io: data, filename: filename,
                                           content_type: content_type, metadata: metadata
end

CSV.foreach('db/CSV Output - subject_export.csv', headers: true) do |row|
  Subject.create!(row.to_hash)
  p row["subject"]
end

CSV.foreach('db/CSV Output - unit_export.csv', headers: true) do |row|
  Topic.create!(row.to_hash)
  p row["name"]
end

CSV.foreach('db/CSV Output - question_export.csv', headers: true) do |row|
  if row['image'].nil?
    Question.create!(id: row['id'], topic_id: row['topic_id'], question_text: row['question_text'], question_type: row['question_type'] )
  else
    google_location = row['image'].gsub(/open?/, 'uc')

    http_conn = Faraday.new do |builder|
      builder.adapter Faraday.default_adapter
    end 
    response = http_conn.get google_location

    filename = google_location.from(31) + '.png'

    unless defined? /HREF=".*"/.match(response.body)[0]
      p "ERROR WITH: " + filename
      next
    end

    new_google_loc = /HREF=".*"/.match(response.body)[0].from(6).chop

    response = http_conn.get new_google_loc

    image = create_file_blob(data: StringIO.new(response.body), filename: filename, content_type: 'image/jpg')
    html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>#{row['question_text']}</p>)
    Question.create!(id: row['id'], topic_id: row['topic_id'], question_text: html , question_type: row['question_type'] )
  end

end

# Answers from the Google spreadsheets come in a set order, with correct answer first.
# Randomise these answers
question_id = 0
answer_array = []
CSV.foreach('db/CSV Output - answer_export.csv', headers: true) do |row|
  if question_id == row['question_id']
    answer_array.push(row)
  else
    answer_array.shuffle.each do |r|
      Answer.create!(r.to_hash)
    end

    answer_array = []
    answer_array.push(row)
  end

  question_id = row['question_id']

end

Answer.create!(row.to_hash)

Multiplier.create([ {score: 0, multiplier: 1}, {score: 4, multiplier: 2}, {score: 7, multiplier: 4}, {score: 10, multiplier: 10} ] )

Customisation.create([ 
  {customisation_type: 0, cost: 100, name: 'Race Red', value: 'red'},
  {customisation_type: 0, cost: 100, name: 'Climber Orange', value: 'orange'},
  {customisation_type: 0, cost: 100, name: 'Ferrari Dark Red', value: 'darkred'},
  {customisation_type: 0, cost: 100, name: 'Hiking Dark Blue', value: 'darkblue'},
  {customisation_type: 0, cost: 100, name: 'Football Dark Green', value: 'darkgreen'},
  {customisation_type: 0, cost: 100, name: 'Sunshine Yellow', value: 'yellow'}  
])

case Rails.env
  when "development"
    Admin.create(email: 'n.houlton@grange.outwood.com', password: 'password', password_confirmation: 'password', role: 'super')
    subject = Subject.where(name:'Computer Science').first
    DefaultSubjectMap.create(name: 'Sociology', subject: subject)
end


