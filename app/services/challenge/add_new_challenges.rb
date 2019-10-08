class Challenge::AddNewChallenges < ApplicationService
  def initialize(multiplier: 1, duration: 7.days)
    @subjects = Subject.all
    @multiplier = multiplier
    @duration = duration
  end

  def call
    add_new_challenges
  end

  def add_new_challenges
    @subjects.each do |s|
      Challenge.create_challenge(s, multiplier: @multiplier, duration: @duration)
    end
  end
end
