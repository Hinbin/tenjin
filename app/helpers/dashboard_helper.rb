# frozen_string_literal: true

module DashboardHelper
  def challenge_progress_display(challenge, challenge_progresses)
    challenge_progress = challenge_progresses.select { |cp| cp.challenge_id == challenge.id }
    return "0%" if challenge_progress.empty?
    return content_tag(:i, nil, class: "fas fa-check", style: "color:green") if challenge_progress.first.completed

    challenge_progress.first.progress.to_s
  end

  def homework_status_icon(homework_progress)
    if homework_progress.homework.due_date.past? && !homework_progress.completed?
      return content_tag(:i, nil, class: "fas fa-exclamation", style: "color:yellow")
    end

    boolean_icon(homework_progress.completed?)
  end

  def challenge_time_left(challenge)
    return "Ended" if challenge.end_date.past?

    distance_of_time_in_words(Time.current, challenge.end_date)
  end
end
