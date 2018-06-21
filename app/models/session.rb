class Session < ApplicationRecord
  belongs_to :user

  def start!
    self.numQuestionsAsked = 0
    questions = Question.where("topic_id < ?", 13).order("RANDOM()").take(10).pluck(:id)
    self.questionsAsked_id = questions
  end

  def getQuestion
    self.questionsAsked_id[self.numQuestionsAsked]
  end

  def nextQuestion!
    self.numQuestionsAsked = self.numQuestionsAsked + 1
    self.save
  end

  def endSession!
    self.delete
  end

end
