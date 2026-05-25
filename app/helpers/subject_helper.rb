# frozen_string_literal: true

module SubjectHelper
  def subject_image(subject)
    name = "images/#{subject.name.parameterize}.jpg"

    asset_exists?(name) ? name : "images/default-subject.jpg"
  end

  private

  def asset_exists?(name)
    path = name.starts_with?("static/") ? name : "static/#{name}"
    Shakapacker.manifest.lookup(path).present?
  end
end
