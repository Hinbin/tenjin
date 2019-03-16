class CreateChallenges < ActiveRecord::Migration[5.2]
  def change
    create_table :challenges do |t|
      t.integer :challenge_type
      t.datetime :start_date
      t.datetime :end_date
      t.integer :number_required
      t.integer :points
      t.references :topic, foreign_key: true

      t.timestamps
    end
  end
end


# def up
#   execute <<-DDL
#     CREATE TYPE challenge_types AS ENUM (
#       'number_correct', 'streak', 'number_of_points'
#     );
#   DDL

#   create_table :challenges do |t|
#     t.datetime :start_date
#     t.datetime :end_date
#     t.integer :number_required
#     t.integer :points
#     t.references :topic, foreign_key: true
#     t.column :challenge_types, :challenge_types

#     t.timestamps
#   end
# end

# def down
#   remove_column :challenges, :challenge_types
#   execute "DROP type challenge_types;"

#   drop_table :challenges
# end
