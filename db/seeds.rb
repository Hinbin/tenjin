# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

q1 = Question.create(text:'The answer is answer')
q1.answers.create(text:'answer', correct: true)

q2 = Question.create(text:'The answer is cheese')
q2.answers.create(text:'cheese', correct: true)

q3 = Question.create(text:'The answer is hello')
q3.answers.create(text:'hello', correct: true)

