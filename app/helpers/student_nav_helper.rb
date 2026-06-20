# frozen_string_literal: true

# StudentNavHelper — utilities for the student app shell nav (Plan 01, Phase 5).
module StudentNavHelper
  NAV_ITEMS = [
    { id: :home,   icon: :home,   en: 'Home',  jp: '家',  path_method: :dashboard_path }.freeze,
    { id: :tasks,  icon: :list,   en: 'Tasks', jp: '宿題', path_method: :homeworks_path }.freeze,
    { id: :quests, icon: :target, en: 'Quests', jp: '挑戦', path_method: :dashboard_path, anchor: 'challenges' }.freeze,
    { id: :ranks,  icon: :trophy, en: 'Ranks', jp: '順位', path_method: :leaderboard_index_path }.freeze,
    { id: :shop,   icon: :tag,    en: 'Shop',  jp: '店',  path_method: :show_available_customisations_path }.freeze
  ].freeze

  # Returns the nav item list; called from partials so the constant is accessible in module scope.
  def student_nav_items
    NAV_ITEMS
  end

  CONTROLLER_TO_NAV = {
    'dashboard' => :home, 'homeworks' => :tasks,
    'leaderboard' => :ranks, 'customisations' => :shop
  }.freeze

  # Which nav item is active based on the current controller/action.
  def student_nav_active_item
    CONTROLLER_TO_NAV[controller_name]
  end

  def student_nav_active?(item_id)
    student_nav_active_item == item_id
  end

  # Section title for the contextual top strip.
  def student_section_title
    item = NAV_ITEMS.find { |n| n[:id] == student_nav_active_item }
    item ? item[:en] : 'Tenjin'
  end

  # Full URL for a nav item.
  def student_nav_path(item)
    base = send(item[:path_method])
    item[:anchor] ? "#{base}##{item[:anchor]}" : base
  end

  # True when the quiz HUD owns the full screen — shell chrome is hidden.
  def student_in_quiz?
    controller_name == 'quizzes'
  end
end
