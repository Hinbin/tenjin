# frozen_string_literal: true

# TeacherNavHelper — nav model for the teacher/admin app shell (mirrors StudentNavHelper).
#
# Items are role-gated: every employee gets Classrooms/Lessons/Leaderboard; question authors get
# Edit Questions; school admins get User Admin + Setup Classrooms. Labels and hrefs match the
# legacy navbar so existing links/specs keep working.
module TeacherNavHelper
  def teacher_nav_items
    base_nav_items + author_nav_items + admin_nav_items
  end

  CONTROLLER_TO_NAV = {
    'dashboard' => :classrooms, 'classrooms' => :classrooms, 'lessons' => :lessons,
    'leaderboard' => :ranks, 'topics' => :questions, 'questions' => :questions, 'users' => :admin_users,
    'settings' => :appearance
  }.freeze

  # The gap-analysis surfaces all live on ClassroomsController, so disambiguate by action before
  # falling back to the controller map (which sends plain `classrooms` to the Classrooms tab).
  GAP_ANALYSIS_ACTIONS = %w[gap_analysis gaps student_gap].freeze

  def teacher_nav_active_item
    return :gap_analysis if controller_name == 'classrooms' && GAP_ANALYSIS_ACTIONS.include?(action_name)

    CONTROLLER_TO_NAV[controller_name]
  end

  def teacher_nav_active?(item_id)
    teacher_nav_active_item == item_id
  end

  # Section title for the contextual top strip.
  def teacher_section_title
    item = teacher_nav_items.find { |n| n[:id] == teacher_nav_active_item }
    item ? item[:en] : 'Tenjin'
  end

  private

  def base_nav_items
    [
      { id: :classrooms,   icon: :home,   en: 'Classrooms',   jp: '教室', path: dashboard_path },
      { id: :gap_analysis, icon: :target, en: 'Analysis', jp: 'ギャップ', path: gap_analysis_classrooms_path },
      { id: :lessons,      icon: :book,    en: 'Lessons',      jp: '授業',   path: lessons_path },
      { id: :ranks,        icon: :trophy,  en: 'Leaderboard',  jp: '順位',   path: leaderboard_index_path },
      { id: :appearance,   icon: :sparkle, en: 'Appearance',   jp: '装い',   path: settings_path }
    ]
  end

  def author_nav_items
    return [] unless current_user.has_role?(:question_author, :any)

    [{ id: :questions, icon: :scroll, en: 'Edit Questions', jp: '問題', path: topics_path }]
  end

  def admin_nav_items
    return [] unless current_user.has_role?(:school_admin)

    [
      { id: :admin_users, icon: :crown, en: 'User Admin',       jp: '管理', path: users_path },
      { id: :setup,       icon: :globe, en: 'Setup Classrooms', jp: '設定', path: classrooms_path }
    ]
  end
end
