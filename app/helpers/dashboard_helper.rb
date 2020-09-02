# frozen_string_literal: true

module DashboardHelper
  def write_challenge_progress(challenge_progress)
    return '0%' if challenge_progress.nil?
    return '<i class="fas fa-check" style="color:green"></i>'.html_safe if challenge_progress.completed

    challenge_progress.progress.to_i.to_s
  end

  def check_overdue(homework_progress)
    if homework_progress.homework.due_date.past? && homework_progress.completed == false
      return '<i class="fas fa-exclamation" style="color:yellow"></i>'.html_safe
    end

    boolean_icon(homework_progress.completed?)
  end

  def challenge_time_left(challenge)
    return 'Soon' if challenge.end_date.past?

    distance_of_time_in_words(Time.current, challenge.end_date)
  end
end
