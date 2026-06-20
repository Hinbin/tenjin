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

# Phase 4 reward-shop catalog: skins, palettes and the five cosmetic slots. Idempotent
# (find_or_initialize by type + value) and safe to re-run on every deploy.
load Rails.root.join('db/seeds/cosmetics.rb')

# Load the full set of fake accounts, questions and lessons in development, or on
# an explicitly opted-in non-production deploy (SEED_TEST_USERS=true). The real
# production blueprint never sets that flag, so this can never run on the live site.
if Rails.env.development? || ENV['SEED_TEST_USERS'] == 'true'
  load Rails.root.join('db/seeds/development_questions.rb')
  load Rails.root.join('db/seeds/development_users.rb')
  load Rails.root.join('db/seeds/development_lessons.rb')
end
