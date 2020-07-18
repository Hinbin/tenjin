# frozen_string_literal: true

# Adds a role to a user
class User::ChangeUserRole < ApplicationService
  def initialize(user, role, action, subject = nil)
    @user = user
    @role = role
    @action = action
    @subject = Subject.find(subject) unless subject.blank?
  end

  def call
    return return_error('User not found') unless @user.present?
    return return_error('Role not found') unless @role.present?
    return return_error('Action must be "add" or "remove"') unless %i[add remove].include? @action

    if %w[lesson_author question_author].include?(@role) && @subject.blank?
      return return_error('Must include a subject with a lesson or quesiton author role')
    end

    change_user_role

    OpenStruct.new(success?: true, user: @user, role: @role, action: @action)
  end

  private

  def return_error(msg)
    OpenStruct.new(success?: false, user: @user, role: @role, action: @action, errors: msg)
  end

  def change_user_role
    case @action
    when :add
      add_user_role
    when :remove
      remove_user_role
    end
  end

  def add_user_role
    if @role == 'school_admin'
      @user.add_role @role
    elsif %w[question_author lesson_author].include? @role
      @user.add_role @role, @subject
    end
  end

  def remove_user_role
    if @role == 'school_admin'
      @user.remove_role @role
    elsif %w[question_author lesson_author].include? @role
      @user.remove_role @role, @subject
    end
  end
end
