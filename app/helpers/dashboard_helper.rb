module DashboardHelper
  def write_challenge_progress(cp)
    return '0%' if cp.nil?
    return icon('fas', 'check', style: 'color:green') if cp.completed == true

    progress_string = cp.progress.to_s

    progress_string = 0.to_s if cp.progress.nil?

    progress_string += '%' unless cp.challenge.number_of_points?

    progress_string
  end

  def check_overdue(homework_progress)
    return icon('fas', 'exclamation', style: 'color:yellow') if homework_progress.homework.due_date < DateTime.now && homework_progress.completed == false

    return boolean_icon(homework_progress.completed?)
  end
end
