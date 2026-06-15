# frozen_string_literal: true

unless Rails.env.development?
  raise "Development user seeds can only be loaded in development, not #{Rails.env}."
end

PASSWORD = 'password'

def upsert_admin(email:, role:)
  admin = Admin.find_or_initialize_by(email:)
  admin.role = role
  admin.password = PASSWORD
  admin.password_confirmation = PASSWORD
  admin.save!
  admin
end

def upsert_school_group(name:)
  SchoolGroup.find_or_create_by!(name:)
end

def upsert_school(name:, client_id:, token:, school_group:)
  School.find_or_initialize_by(client_id:).tap do |school|
    school.name = name
    school.token = token
    school.school_group = school_group
    school.permitted = true
    school.sync_status = 'successful'
    school.save!
  end
end

def upsert_subject(name:)
  Subject.find_or_create_by!(name:)
end

def upsert_topic(subject:, name:)
  Topic.find_or_create_by!(subject:, name:) do |topic|
    topic.active = true
  end
end

def upsert_classroom(school:, subject:, name:, code:)
  Classroom.find_or_initialize_by(client_id: "development-#{code.downcase}").tap do |classroom|
    new_record = classroom.new_record?
    classroom.name = name
    classroom.code = code
    classroom.description = "#{name} development classroom"
    classroom.school = school
    classroom.subject = subject
    classroom.disabled = false
    classroom.enrollments_count = 0 if new_record && classroom.enrollments_count.nil?
    classroom.save!
  end
end

def upsert_user(school:, username:, forename:, surname:, role:, upi:, email: '')
  User.find_or_initialize_by(upi:).tap do |user|
    user.school = school
    user.username = username
    user.forename = forename
    user.surname = surname
    user.role = role
    user.provider = 'Development'
    user.email = email
    user.challenge_points ||= 0
    user.disabled = false
    user.password = PASSWORD
    user.password_confirmation = PASSWORD
    user.save!
  end
end

def enroll(user:, classroom:)
  Enrollment.find_or_create_by!(user:, classroom:)
end

# Give a student progress on a single challenge. Roughly a third of progress rows are
# completed (and awarded); the rest are part-way through. Idempotent on user + challenge.
def upsert_challenge_progress(user:, challenge:, completed:)
  ChallengeProgress.find_or_initialize_by(user:, challenge:).tap do |cp|
    cp.completed = completed
    cp.awarded = completed
    cp.progress = completed ? challenge.number_required : rand(0...challenge.number_required)
    cp.save!
  end
end

def seed_challenge_progress(students)
  challenges = Challenge.all.to_a
  return if challenges.empty?

  students.each_with_index do |student, student_index|
    # Each student works on a rotating window of four challenges so progress is spread
    # across topics rather than all landing on the same few.
    student_challenges = challenges.rotate(student_index * 4).first(4)

    student_challenges.each_with_index do |challenge, challenge_index|
      completed = ((student_index + challenge_index) % 3).zero?
      upsert_challenge_progress(user: student, challenge:, completed:)
    end
  end
end

upsert_admin(email: 'n.houlton@grange.outwood.com', role: 'super')

school_group = upsert_school_group(name: 'Development School Group')
school = upsert_school(
  name: 'Tenjin Development School',
  client_id: 'development-school',
  token: 'development-token',
  school_group:
)

subjects = {
  'Computer Science' => %w[Algorithms Networks Programming Data],
  'Mathematics' => ['Number', 'Algebra', 'Geometry', 'Statistics'],
  'Science' => ['Biology', 'Chemistry', 'Physics', 'Working Scientifically']
}

classrooms = subjects.each_with_object({}) do |(subject_name, topic_names), memo|
  subject = upsert_subject(name: subject_name)
  topic_names.each { |topic_name| upsert_topic(subject:, name: topic_name) }

  memo[subject_name] = [
    upsert_classroom(school:, subject:, name: "7 #{subject_name}", code: "7#{subject_name.first}"),
    upsert_classroom(school:, subject:, name: "8 #{subject_name}", code: "8#{subject_name.first}")
  ]
end

school_admin = upsert_user(
  school:,
  username: 'schooladmin',
  email: 'schooladmin@example.com',
  forename: 'Sam',
  surname: 'Admin',
  role: 'employee',
  upi: 'development-school-admin'
)
school_admin.add_role(:school_admin)
Subject.where(name: subjects.keys).each do |subject|
  school_admin.add_role(:lesson_author, subject)
  school_admin.add_role(:question_author, subject)
end

teachers = [
  upsert_user(
    school:,
    username: 'teacher1',
    email: 'teacher1@example.com',
    forename: 'Tara',
    surname: 'Teacher',
    role: 'employee',
    upi: 'development-teacher-1'
  ),
  upsert_user(
    school:,
    username: 'teacher2',
    email: 'teacher2@example.com',
    forename: 'Theo',
    surname: 'Teacher',
    role: 'employee',
    upi: 'development-teacher-2'
  )
]

students = 24.times.map do |index|
  number = index + 1
  upsert_user(
    school:,
    username: "student#{number}",
    forename: "Student#{number}",
    surname: 'Learner',
    role: 'student',
    upi: "development-student-#{number}"
  )
end

students.first(10).each { |student| student.update!(challenge_points: 1000) }

classrooms.values.flatten.each_with_index do |classroom, index|
  enroll(user: teachers[index % teachers.length], classroom:)
  enroll(user: school_admin, classroom:)
end

students.each_with_index do |student, index|
  classrooms.values.flatten.each_with_index do |classroom, classroom_index|
    enroll(user: student, classroom:) if (index + classroom_index).even?
  end
end

seed_challenge_progress(students)

puts 'Development users seeded.'
puts "Admin: n.houlton@grange.outwood.com / #{PASSWORD}"
puts "School admin (+ lesson/question author for all subjects): schooladmin / #{PASSWORD}"
puts "Teachers: teacher1, teacher2 / #{PASSWORD}"
puts "Students: student1 through student24 / #{PASSWORD}"
