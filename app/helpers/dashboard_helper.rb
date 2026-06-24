# frozen_string_literal: true

module DashboardHelper
  SUBJECT_META = {
    'Computer Science' => { glyph: :chip, neon: 'var(--n1)', short: 'CS', jp: 'コンピュータ' },
    'Mathematics' => { glyph: :target, neon: 'var(--n2)', short: 'MAT', jp: '数学' },
    'Science' => { glyph: :bolt,   neon: 'var(--n3)', short: 'SCI', jp: '科学'          },
    'English' => { glyph: :scroll, neon: 'var(--n2)', short: 'ENG', jp: '英語'          },
    'History' => { glyph: :book,   neon: 'var(--n3)', short: 'HIS', jp: '歴史'          },
    'Geography' => { glyph: :globe, neon: 'var(--n1)', short: 'GEO', jp: '地理' }
  }.freeze

  def subject_meta(name)
    SUBJECT_META[name] || { glyph: :book, neon: 'var(--n2)', short: name.upcase.first(3), jp: name.first(6) }
  end

  def challenge_complete?(challenge)
    @challenge_progresses.any? { |cp| cp.challenge_id == challenge.id && cp.completed }
  end

  def topic_mastery_pct(topic_id, max_score: 500)
    score = @topic_scores&.dig(topic_id)&.score.to_i
    (score * 100.0 / max_score).round.clamp(0, 100)
  end

  def write_challenge_progress(challenge, challenge_progresses)
    challenge_progress = challenge_progresses.select { |cp| cp.challenge_id == challenge.id }
    return '0%' if challenge_progress.empty?
    return '<i class="fas fa-check" style="color:green"></i>'.html_safe if challenge_progress.first.completed

    challenge_progress.first.progress.to_i.to_s
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

  # Turns a due date into a relative, human-readable phrase, e.g.
  # "in 6 days at 9am", "in 3 hours", "3 days ago".
  def humanized_due_date(due)
    return '' if due.blank?

    now      = Time.current
    distance = distance_of_time_in_words(now, due)

    return "#{distance.capitalize} ago" if due.past?

    phrase = "in #{distance}"
    phrase += " at #{due_time_of_day(due)}" if due.to_date != now.to_date
    phrase
  end

  # Compact clock label for a due time, e.g. "9am" or "3:30pm".
  def due_time_of_day(due)
    fmt = due.min.zero? ? '%-l%P' : '%-l:%M%P'
    due.strftime(fmt)
  end
end
