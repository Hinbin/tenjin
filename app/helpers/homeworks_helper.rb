module HomeworksHelper
  def report_progress(homework_progress)
    completed = homework_progress.where(completed: true).count
    number_of_students = homework_progress.count
    (completed.to_s + ' / ' + number_of_students.to_s) +
      ' - ' + number_to_percentage((completed.to_f / number_of_students.to_f) * 100, precision: 0)
  end
end
