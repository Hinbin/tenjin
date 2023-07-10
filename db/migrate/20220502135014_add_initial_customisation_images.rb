class AddInitialCustomisationImages < ActiveRecord::Migration[6.0]
  def up
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'red')
      .image.attach(io: File.open('app/javascript/images/athletics.jpg'), filename: 'athletics.jpg', content_type: 'image/jpeg')
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'orange')
      .image.attach(io: File.open('app/javascript/images/orange-climbing.jpg'), filename: 'orange-climbing.jpg', content_type: 'image/jpeg')
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'darkred')
      .image.attach(io: File.open('app/javascript/images/darkred-ferrari.jpg'), filename: 'darkred-ferrari.jpg', content_type: 'image/jpeg')
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'darkblue')
      .image.attach(io: File.open('app/javascript/images/darkblue-hiking.jpg'), filename: 'darkblue-hiking.jpg', content_type: 'image/jpeg')
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'darkgreen')
      .image.attach(io: File.open('app/javascript/images/darkgreen-football.jpg'), filename: 'darkgreen-football.jpg', content_type: 'image/jpeg')
    Customisation.find_or_create_by(customisation_type: 'dashboard_style', value: 'yellow')
      .image.attach(io: File.open('app/javascript/images/yellow-cheerful.jpg'), filename: 'yellow-cheerful.jpg', content_type: 'image/jpeg')
  end

  def down
    Customisation.all.each do |c|
      c.image.purge
    end
  end
end
