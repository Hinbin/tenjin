# frozen_string_literal: true

module ClassroomsHelper
  def student_homeworks(student, homework_progress)
    entries = homework_progress.find_all { |hp| hp.user_id == student.id }
    entries.take(5).map! { |e| boolean_icon(e.completed?) }.join
  end

  def sync_status_button
    case @school.sync_status
    when 'never', 'successful'
      sync_button
    when 'failed', 'needed'
      sync_needed_button
    when @school.sync_status == 'syncing' && (Time.now - School.first.updated_at) < 240
      sync_timeout_button
    else
      'Refresh the page to see the current sync status'
    end
  end

  # Teacher anomaly cell: number of recent answers flagged as answered-too-fast (the signature of an
  # auto-answering browser extension). Zero stays blank so a clean class isn't littered with noise;
  # any flags render a red count with a hover explanation. See AskedQuestion.fast_flag_counts.
  def fast_flag_cell(count)
    return '' if count.to_i.zero?

    tag.span(count,
             class: 'fast-flag-count',
             style: 'color:var(--incorrect);font-weight:700',
             title: 'Answers flagged as answered too fast to be genuine — possible auto-answering')
  end

  def report_progress(homework)
    percent = number_to_percentage(homework.completed_count / homework.count.to_f * 100, precision: 0)
    "#{homework.completed_count} / #{homework.count} - #{percent}"
  end

  # --- Gap analysis presentation -------------------------------------------------------------------

  # A metric-card label with a hover/focus tooltip explaining the term. The trailing ⓘ marker reveals
  # the explanation via a CSS tooltip (data-tooltip drives the ::after bubble); keyboard-focusable and
  # mirrored into title/aria-label so it isn't mouse-only.
  def gap_card_label(text, explanation)
    tag.span(class: 'tj-gap-card-label') do
      safe_join([text, ' ',
                 tag.span('ⓘ', class: 'tj-gap-info', tabindex: 0, role: 'note',
                               'data-tooltip': explanation, title: explanation, 'aria-label': explanation)])
    end
  end

  # A 0..1 score as a whole-number percentage; em dash for "no data" (nil).
  def gap_percent(score)
    return '—' if score.nil?

    number_to_percentage(score * 100, precision: 0)
  end

  # Difficulty band as a coloured chip (easy/medium/hard from Analytics::QuestionDifficulty).
  def difficulty_band_chip(band)
    return '' if band.nil?

    tag.span(band.to_s.capitalize, class: "tj-gap-band tj-gap-band--#{band}")
  end

  # Cohort standing as a coloured chip (above / on_par / below / unknown).
  def standing_chip(standing)
    labels = { above: 'Above average', on_par: 'On par', below: 'Below average', unknown: 'No data' }
    tag.span(labels.fetch(standing, 'No data'), class: "tj-gap-standing tj-gap-standing--#{standing}")
  end

  # Heatmap cell tint: low mean score => hot (red), high => cool (green). Drives the topic heatmap.
  def heat_style(score)
    hue = (score.to_f * 120).round # 0 = red, 120 = green
    "background:hsl(#{hue},70%,88%)"
  end

  def sync_button
    link_to 'Sync Classrooms & Users', sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tj-btn-primary tj-btn--full'
  end

  def sync_needed_button
    link_to 'School sync required. Click here to start.',
            sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tj-btn-danger tj-btn--full'
  end

  def sync_timeout_button
    link_to 'Last Sync Timed Out.  Press here to try again.', sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tj-btn-dark tj-btn--full'
  end
end
