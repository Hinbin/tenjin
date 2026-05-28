# frozen_string_literal: true

# Adds a role to a user
class User::ChangeUserRole < ApplicationService
  def initialize(user, role, action, subject = nil)
    @user = user
    @role = role
    @action = action
    @subject = Subject.find(subject) if subject.present?
  end

  def call
    return return_error("User not found") if @user.blank?
    return return_error("Role not found") if @role.blank?
    return return_error('Action must be "add" or "remove"') unless %i[add remove].include? @action

    if %w[lesson_author question_author].include?(@role) && @subject.blank?
      return return_error("Must include a subject with a lesson or question author role")
    end

    change_user_role

    OpenStruct.new(success?: true, user: @user, role: @role, action: @action)
  end

  private

  def return_error(msg)
    OpenStruct.new(success?: false, user: @user, role: @role, action: @action, errors: msg)
  end

  def change_user_role
    method = (@action == :add) ? :add_role : :remove_role
    if @role == "school_admin"
      @user.send(method, @role)
    elsif %w[question_author lesson_author].include?(@role)
      @user.send(method, @role, @subject)
    else
      raise ArgumentError, "Unrecognised role: #{@role}"
    end
  end
end
