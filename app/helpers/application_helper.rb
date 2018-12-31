module ApplicationHelper

  def boolean_icon(status)
    if status
      icon('fas', 'check', style: 'color:green')
    else
      icon('fas', 'times', style: 'color:red')
    end
  end

  def print_subject_image(url)
    url = Rails.application.assets.find_asset(url).nil? ? nil : url
    image_url url || 'default-subject.jpg'
  end

end
