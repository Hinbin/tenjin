class Answer < ApplicationRecord
  belongs_to :question, counter_cache: true
end
