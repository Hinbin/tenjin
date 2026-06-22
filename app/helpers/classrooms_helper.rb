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
