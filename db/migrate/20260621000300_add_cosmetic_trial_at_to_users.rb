# frozen_string_literal: true

class AddCosmeticTrialAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # When the user's current try-before-you-buy window started; gates the cooldown before they can
    # start another trial. nil = never trialled.
    add_column :users, :cosmetic_trial_at, :datetime
  end
end
