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

  def get_user_classes(student)
    student.enrollments.map { |e| e.classroom.name }.join(', ')
  end

  def link_to_add_row(name, form, association, **args)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.simple_fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize, f: builder)
    end
    link_to(name, '#', class: 'add_fields ' + args[:class], data: { id: id, fields: fields.delete("\n") })
  end
end
