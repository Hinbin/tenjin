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

  # Teacher anomaly indicator: prefixes a student's name with a red warning mark when they have recent
  # answers flagged as answered-too-fast (the signature of an auto-answering browser extension). A clean
  # student renders just their name so the roster isn't littered with noise. See
  # AskedQuestion.fast_flag_counts and the class-wide banner on classrooms/show.
  def fast_flag_indicator(name, count)
    count = count.to_i
    return name if count.zero?

    flagged = "#{count} #{'answer'.pluralize(count)} flagged as answered too fast to be genuine"
    safe_join([
      tag.i(class: 'fas fa-exclamation-triangle fast-flag-mark',
            style: 'color:var(--incorrect);margin-right:0.35rem',
            aria: { hidden: true },
            title: "#{flagged} — possible auto-answering"),
      name
    ])
  end

  def report_progress(homework)
    percent = number_to_percentage(homework.completed_count / homework.count.to_f * 100, precision: 0)
    "#{homework.completed_count} / #{homework.count} - #{percent}"
  end

  def sync_button
    link_to 'Sync Classrooms & Users', sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tjs-btn tjs-btn--primary'
  end

  def sync_needed_button
    link_to 'School sync required. Click here to start.',
            sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tjs-btn tjs-btn--danger'
  end

  def sync_timeout_button
    link_to 'Last Sync Timed Out.  Press here to try again.', sync_school_path(current_user.school),
            data: { turbo_method: :patch },
            id: 'syncButton',
            class: 'tjs-btn tjs-btn--ghost'
  end
end
