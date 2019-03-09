class Challenge::AddNewChallenges
  def initialize
    @subjects = Subject.all
  end

  def call
    add_new_challenges
  end

  def add_new_challenges
    @subjects.each do |s|
      Challenge.create_challenge(s)
    end
  end
end
