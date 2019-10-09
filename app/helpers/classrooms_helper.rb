module ClassroomsHelper
  def student_homeworks(student, homework_progress)
    entries = homework_progress.find_all { |hp| hp.user_id == student.id }
    entries.take(5).map! { |e| boolean_icon(e.completed?) }.join
  end

  def sync_status_button
    case @school.sync_status
    when 'never', 'successful'
      link_to 'Sync Classrooms & Users', sync_school_path(current_user.school),
              method: :patch,
              id: 'syncButton',
              class: 'btn btn-primary btn-block my-3'
    when 'failed', 'needed'
      link_to 'School sync required. Click here to start.',
              sync_school_path(current_user.school),
              method: :patch,
              id: 'syncButton',
              class: 'btn btn-danger btn-block my-3'
    else
      'Refresh the page to see the current sync status'
    end
  end
end
