# frozen_string_literal: true

module HomeworksHelper
  def report_progress(homework_progress)
    completed = homework_progress.where(completed: true).count
    total = homework_progress.count
    percent = number_to_percentage(completed / total.to_f * 100, precision: 0)
    "#{completed} / #{total} - #{percent}"
  end
end
