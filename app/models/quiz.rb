# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :user

  def question
    questions_asked_id[num_questions_asked]
  end

end
