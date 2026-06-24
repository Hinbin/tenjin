# frozen_string_literal: true

# SettingsController — student-facing settings surface (Plan 01, Phase 5).
# Exposes skin / palette / mode / motion preferences; each form submission equips or sets one
# dimension so the server remains the single source of truth for the equipped theme.
class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user, :show?
    board = Customisation::ShopBoard.call(current_user)
    @skins_category = board.categories.find { |c| c.type == 'skin' }
    # The remaining equip slots (scenes, motions, avatar/nameplate/… cosmetics) so the appearance
    # surface can manage every owned customisation, not just skins/palettes. Skins stay separate
    # because they nest palettes and drive the skin-locked scene/motion options.
    @look_categories = board.categories.reject { |c| c.type == 'skin' }
    @mode = board.mode
    @wallet = board.wallet
  end

  def update
    authorize current_user, :update?
    handle_motion if params[:motion_pref].present?
    redirect_to settings_path, notice: 'Settings saved.'
  end

  private

  def handle_motion
    pref = ActiveModel::Type::Boolean.new.cast(params[:motion_pref])
    current_user.update!(motion_pref: pref)
  end
end
