# frozen_string_literal: true

class Challenge::AddNewChallenges < ApplicationService
  def initialize(multiplier: 1, duration: 7.days, daily: false)
    @multiplier = multiplier
    @duration = duration
    @daily = daily
  end

  def call
    Subject.find_each do |s|
      Challenge.create_challenge(s, multiplier: @multiplier, duration: @duration, daily: @daily)
    end
  end
end
