# frozen_string_literal: true

class AddPseudonymToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :pseudonym, :string

    say_with_time 'Backfilling user pseudonyms' do
      User.reset_column_information
      User.where(pseudonym: nil).find_each do |user|
        seed = user.upi.present? ? Zlib.crc32(user.upi) : user.id
        user.update_column(:pseudonym, Leaderboard::Pseudonym.generate(seed))
      end
    end
  end

  def down
    remove_column :users, :pseudonym
  end
end
