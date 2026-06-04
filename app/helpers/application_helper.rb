# frozen_string_literal: true

module ApplicationHelper
  FLASH_CLASSES = {
    "success" => "alert-success",
    "error" => "alert-danger",
    "alert" => "alert-danger",
    "notice" => "alert-info"
  }.freeze

  def bootstrap_flash_class(type)
    FLASH_CLASSES.fetch(type, "alert-warning")
  end

  def boolean_icon(status)
    if status
      content_tag(:i, nil, class: "fas fa-check", style: "color:green")
    else
      content_tag(:i, nil, class: "fas fa-times", style: "color:red")
    end
  end

  def render_small_separator(style = nil, margin: "mb-5")
    color = style&.value || @dashboard_style&.value || "red"
    content_tag(:div, nil, class: "heading-divider #{margin}", style: "color: #{color}", aria: {hidden: true})
  end

  def render_dashboard_style(style)
    return "" if style.nil?
    return "" unless style.image.attached?

    "background:linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0.5)), url(#{rails_blob_url(style.image)}) no-repeat;"
  end

  def user_class_names(student)
    student.enrollments.map { |e| e.classroom.name }.join(", ")
  end

  def link_to_add_row(name, form, association, **args)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.simple_fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize, f: builder)
    end
    link_to(name, "#",
      class: args[:class].to_s,
      data: {action: "click->nested-fields#add", id: id, fields: fields.delete("\n")})
  end
end
