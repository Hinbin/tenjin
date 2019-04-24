# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

def create_file_blob(filename:, content_type:, metadata: nil)
  ActiveStorage::Blob.create_after_upload! io: File.open(Pathname.new(File.join(Pathname.getwd, 'db', 'downloads', filename))), filename: filename,
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

CSV.foreach('db/CSV Output - question_export_test.csv', headers: true) do |row|

  if row['image'].nil?
    Question.create!(id: row['id'], topic_id: row['topic_id'], question_text: row['question_text'], question_type: row['question_type'] )
  else
    google_location = row['image'].gsub(/open?/, 'uc')
    p google_location

    http_conn = Faraday.new do |builder|
      builder.adapter Faraday.default_adapter
    end 
    response = http_conn.get google_location

    filename = google_location.from(31) + '.jpg'

    new_google_loc = /HREF=".*"/.match(response.body)[0].from(6).chop
    p new_google_loc
    p filename

    response = http_conn.get new_google_loc

    File.open( File.join(Pathname.getwd, 'db', 'downloads', filename), 'wb' ) { |fp| fp.write(response.body) }

    image = create_file_blob(filename: filename, content_type: 'image/jpg')
    html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>#{row['question_text']}</p>)
    Question.create!(id: row['id'], topic_id: row['topic_id'], question_text: html , question_type: row['question_type'] )
  end

end
