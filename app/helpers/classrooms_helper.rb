# frozen_string_literal: true

module ClassroomsHelper
  SYNC_REFRESH_MESSAGE = "Refresh the page to see the current sync status"

  def student_homeworks(student, homework_progress)
    entries = homework_progress.select { |hp| hp.user_id == student.id }
    safe_join(entries.take(5).map { |e| boolean_icon(e.completed?) })
  end

  def sync_status_button
    case @school.sync_status
    when "never", "successful"
      sync_button
    when "failed", "needed"
      sync_needed_button
    when "syncing"
      ((Time.current - @school.updated_at) < 240) ? sync_timeout_button : SYNC_REFRESH_MESSAGE
    else
      SYNC_REFRESH_MESSAGE
    end
  end

  def report_progress(homework)
    count = homework.count
    return "0 / 0 - 0%" if count.zero?

    percent = number_to_percentage(homework.completed_count / count.to_f * 100, precision: 0)
    "#{homework.completed_count} / #{count} - #{percent}"
  end

  private

  def sync_button
    button_to sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-primary btn-block my-3",
      data: {"sync-notice-target": "button"},
      form: {class: "d-inline", data: {turbo: true}} do
      "Sync Classrooms & Users"
    end
  end

  def sync_needed_button
    button_to sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-danger btn-block my-3",
      data: {"sync-notice-target": "button"},
      form: {class: "d-inline", data: {turbo: true}} do
      "School sync required. Click here to start."
    end
  end

  def sync_timeout_button
    button_to sync_school_path(current_user.school),
      method: :patch,
      id: "syncButton",
      class: "btn btn-secondary btn-block my-3",
      data: {"sync-notice-target": "button"},
      form: {class: "d-inline", data: {turbo: true}} do
      "Last Sync Timed Out.  Press here to try again."
    end
  end
end
