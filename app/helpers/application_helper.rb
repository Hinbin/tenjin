# frozen_string_literal: true

module ApplicationHelper
  def boolean_icon(status)
    if status
      icon('fas', 'check', style: 'color:green')
    else
      icon('fas', 'times', style: 'color:red')
    end
  end

  def asset_exists?(path)
    if Rails.env.production?
      !Rails.application.assets_manifest.find_sources(path).nil?
    else
      !Rails.application.assets.find_asset(path).nil?
    end
  end

  def print_subject_image(url)
    asset_exists?(url) ? image_url(url) : image_url('default-subject.jpg')
  end

  def render_small_separator
    @css_flavour = 'default' if @css_flavour.nil?
    "small mb-5 primary-#{@css_flavour}"
  end

  def get_user_classes(s)
    s.enrollments.map { |e| e.classroom.name }.join(', ')
  end
end
