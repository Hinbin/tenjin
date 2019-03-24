module DashboardHelper
  def write_challenge_progress(cp)
    return '0%' if cp.nil?
    return icon('fas', 'check', style: 'color:green') if cp.completed == true

    progress_string = cp.progress.to_s

    progress_string = 0.to_s if cp.progress.nil?

    progress_string += '%' unless cp.challenge.number_of_points?

    progress_string
  end
end
