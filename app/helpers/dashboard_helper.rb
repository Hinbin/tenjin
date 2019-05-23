module DashboardHelper
  def write_challenge_progress(challenge_progress)
    return '0%' if challenge_progress.nil?
    return icon('fas', 'check', style: 'color:green') if challenge_progress.completed == true

    progress_string = challenge_progress.progress.to_s

    progress_string = 0.to_s if challenge_progress.progress.nil?

    progress_string += '%' unless challenge_progress.challenge.number_of_points?

    progress_string
  end

  def check_overdue(homework_progress)
    if homework_progress.homework.due_date < Time.current && homework_progress.completed == false
      return icon('fas', 'exclamation', style: 'color:yellow')
    end

    boolean_icon(homework_progress.completed?)
  end

  def challenge_time_left(challenge)
    return 'Soon' if Time.current > challenge.end_date

    distance_of_time_in_words(Time.current, challenge.end_date)
  end
end
