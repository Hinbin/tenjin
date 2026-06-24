# frozen_string_literal: true

# SettingsController — student-facing settings surface (Plan 01, Phase 5).
# Exposes skin / palette / mode / motion preferences; each form submission equips or sets one
# dimension so the server remains the single source of truth for the equipped theme.
class SettingsController < ApplicationController
  before_action :authenticate_user!

  # The look slots that render in shared app chrome (the skin backdrop), so they're meaningful on
  # every surface — including teacher pages, which have no player card or quiz HUD. The remaining
  # cosmetics (avatar, nameplate, name_effect, answer_effect, streak_aura) only ever show on the
  # student player card / quiz, so they'd be dead settings for a teacher and are left to the Shop.
  APPEARANCE_LOOK_TYPES = %w[scene motion scene_fx].freeze

  def show
    authorize current_user, :show?
    board = Customisation::ShopBoard.call(current_user)
    @skins_category = board.categories.find { |c| c.type == 'skin' }
    # Scenes, motions & scene-FX — the backdrop look slots, managed alongside skins/palettes. Skins
    # stay separate because they nest palettes and drive the skin-locked scene/motion options.
    @look_categories = board.categories.select { |c| APPEARANCE_LOOK_TYPES.include?(c.type) }
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
