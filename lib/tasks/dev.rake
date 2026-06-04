if Rails.env.development? || Rails.env.test?
  namespace :dev do
    desc "Sample data for local development environment"
    task prime: "db:setup" do
      Admin.create!(
        email: `git config user.email`.chomp,
        password: "password",
        password_confirmation: "password",
        role: "super"
      )
    end

    desc "Populate with users and classrooms from the Wonde test API.
          Requires WONDE_TEST_TOKEN and WONDE_TEST_SCHOOL_ID to be set (e.g. via .env)."
    task bootstrap_wonde: :environment do
      school_token = ENV.fetch("WONDE_TEST_TOKEN")
      school_id = ENV.fetch("WONDE_TEST_SCHOOL_ID")

      school = School.find_by!(client_id: school_id)
      school.update!(token: school_token)

      # Clear any stale syncing flag so SyncSchool doesn't short-circuit silently.
      school.update!(sync_status: :never) if school.syncing?

      puts "Pass 1: syncing classrooms and employees..."
      School::SyncSchool.call(school)
      puts "  Classrooms: #{school.classrooms.count}, Employees: #{school.users.employee.count}"

      # Students only sync into classrooms that have a subject linked.
      # Derive subjects from the classroom name code (e.g. "8x/En2" -> "En").
      # Classrooms with unrecognised codes are left unlinked and will not receive students.
      subjects = {
        "En" => Subject.find_or_create_by!(name: "English"),
        "Bs" => Subject.find_or_create_by!(name: "Business Studies"),
        "Hi" => Subject.find_or_create_by!(name: "History"),
        "Co" => Subject.find_or_create_by!(name: "Computer Science")
      }

      assigned = 0
      school.classrooms.where(subject: nil).find_each do |classroom|
        code = classroom.name.split("/").last.gsub(/\d+$/, "")
        next unless (subject = subjects[code])
        classroom.update!(subject: subject)
        assigned += 1
      end
      puts "  Assigned subjects to #{assigned} classroom(s)"

      puts "Pass 2: syncing students..."
      School::SyncSchool.call(school)
      puts "  Students: #{school.users.student.count}"

      puts "Done."
    end
  end
end
