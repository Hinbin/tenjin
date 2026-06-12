# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

[
  { score: 0, multiplier: 1 },
  { score: 4, multiplier: 2 },
  { score: 7, multiplier: 4 },
  { score: 10, multiplier: 10 }
].each do |attributes|
  Multiplier.find_or_initialize_by(score: attributes[:score]).tap do |multiplier|
    multiplier.multiplier = attributes[:multiplier]
    multiplier.save!
  end
end

[
  { customisation_type: 'dashboard_style', cost: 0, name: 'Race Red', value: 'red' },
  { customisation_type: 'dashboard_style', cost: 100, name: 'Climber Orange', value: 'orange' },
  { customisation_type: 'dashboard_style', cost: 100, name: 'Ferrari Dark Red', value: 'darkred' },
  { customisation_type: 'dashboard_style', cost: 100, name: 'Hiking Dark Blue', value: 'darkblue' },
  { customisation_type: 'dashboard_style', cost: 100, name: 'Football Dark Green', value: 'darkgreen' },
  { customisation_type: 'dashboard_style', cost: 100, name: 'Sunshine Yellow', value: 'yellow' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Force', value: 'black,jedi' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Cat', value: 'black,cat' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Jet', value: 'black,fighter-jet' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Wizard', value: 'black,hat-wizard' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Dog', value: 'black,dog' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Candy', value: 'black,candy-cane' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Emoji', value: 'black,grin' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Frog', value: 'black,frog' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Gelato', value: 'black,ice-cream' },
  { customisation_type: 'leaderboard_icon', cost: 200, name: 'Pizza', value: 'black,pizza-slice' }
].each do |attributes|
  Customisation.find_or_initialize_by(customisation_type: attributes[:customisation_type],
                                      name: attributes[:name]).tap do |customisation|
    customisation.assign_attributes(attributes)
    customisation.save!(validate: false)
  end
end

case Rails.env
when 'development'
  load Rails.root.join('db/seeds/development_questions.rb')
  load Rails.root.join('db/seeds/development_users.rb')
  load Rails.root.join('db/seeds/development_lessons.rb')
end
