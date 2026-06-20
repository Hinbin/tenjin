# frozen_string_literal: true

module ApplicationHelper
  def boolean_icon(status)
    if status
      "<i class='fas fa-check' style='color:green'></i>".html_safe
    else
      "<i class='fas fa-times' style='color:red'></i>".html_safe
    end
  end

  def subject_image_tag(name, **)
    filename = "#{name.parameterize}.jpg"
    path = Rails.root.join("app/assets/images/#{filename}")
    image_tag(path.exist? ? filename : 'default-subject.jpg', **)
  end

  def render_small_separator
    "<hr class='small mb-5 primary' style='border-color: red'>"
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
    link_to(name, '#', class: "add_fields #{args[:class]}", data: { id: id, fields: fields.delete("\n") })
  end
end
