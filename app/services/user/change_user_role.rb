# frozen_string_literal: true

# Adds or removes a role on a user, optionally scoped to a subject.
class User::ChangeUserRole < ApplicationCommand
  SUBJECT_SCOPED_ROLES = %w[lesson_author question_author].freeze
  GLOBAL_ROLES = %w[school_admin].freeze

  def initialize(user:, role:, action:, subject: nil)
    @user = user
    @role = role
    @action = action
    @subject = Subject.find(subject) if subject.present?
  end

  def call
    return failure("User not found") if @user.blank?
    return failure("Role not found") if @role.blank?
    return failure('Action must be "add" or "remove"') unless %i[add remove].include?(@action)

    if SUBJECT_SCOPED_ROLES.include?(@role) && @subject.blank?
      return failure("Must include a subject with a lesson or question author role")
    end

    return failure("Unrecognised role: #{@role}") unless GLOBAL_ROLES.include?(@role) || SUBJECT_SCOPED_ROLES.include?(@role)

    change_user_role
    success
  end

  private

  def change_user_role
    method = (@action == :add) ? :add_role : :remove_role
    if GLOBAL_ROLES.include?(@role)
      @user.send(method, @role)
    elsif SUBJECT_SCOPED_ROLES.include?(@role)
      @user.send(method, @role, @subject)
    end
  end
end
