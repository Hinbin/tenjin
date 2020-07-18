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
    else
      'Refresh the page to see the current sync status'
    end
  end

  def report_progress(homework)
    percent = number_to_percentage(homework.completed_count / homework.count.to_f * 100, precision: 0)
    "#{homework.completed_count} / #{homework.count} - #{percent}"
  end

  def sync_button
    link_to 'Sync Classrooms & Users', sync_school_path(current_user.school),
            method: :patch,
            id: 'syncButton',
            class: 'btn btn-primary btn-block my-3'
  end

  def sync_needed_button
    link_to 'School sync required. Click here to start.',
            sync_school_path(current_user.school),
            method: :patch,
            id: 'syncButton',
            class: 'btn btn-danger btn-block my-3'
  end
end
