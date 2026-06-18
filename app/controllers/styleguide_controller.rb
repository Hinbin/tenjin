# frozen_string_literal: true

# StyleguideController — dev-only proving ground for the reskinnable theme engine (Plan 01,
# Phase 0). Renders the skin-aware primitives so all 4 skins × palettes × dark/light can be
# switched live via the theme Stimulus controller. Never reachable in production.
class StyleguideController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_authorized, raise: false

  before_action :block_in_production

  def show
    @skins = Theme::SkinCatalog::META
    @palettes = Theme::SkinCatalog::PALETTES
  end

  private

  def block_in_production
    head :not_found if Rails.env.production?
  end
end
