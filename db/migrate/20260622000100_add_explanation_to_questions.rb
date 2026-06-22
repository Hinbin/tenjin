# frozen_string_literal: true

class AddExplanationToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :explanation, :text
  end
end
