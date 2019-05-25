module ClassroomsHelper
  def student_homeworks(student, homework_progress)
    entries = homework_progress.find_all { |hp| hp.user_id == student.id }
    return if entries.nil?

    homework_history = ''
    count = 0
    entries.each do |e|
      e.completed? ? homework_history.concat(boolean_icon(true)) : homework_history.concat(boolean_icon(false))
      count += 1
      return homework_history if count >= 5
    end
    homework_history
  end
end
