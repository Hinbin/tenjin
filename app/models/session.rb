class Session < ApplicationRecord
  belongs_to :user

  def start!
    self.numQuestionsAsked = 0
    questions = Question.where("topic_id < ?", 13).order("RANDOM()").take(10).pluck(:id)

    self.questionsAsked_id = questions
  end

end
