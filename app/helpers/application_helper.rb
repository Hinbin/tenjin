module ApplicationHelper
  def boolean_icon(status)
    if status
      icon('fas', 'check', style: 'color:green')
    else
      icon('fas', 'times', style: 'color:red')
    end
  end

  def print_subject_image(url)
    # Find if we have an image for this subject, if not return the default image
    if (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(url).nil?
      url = nil
    end

    image_url url || 'default-subject.jpg'
  end

  def render_small_separator
    @css_flavour = 'default' if @css_flavour.nil?
    'small mb-5 primary-' + @css_flavour
  end
end
