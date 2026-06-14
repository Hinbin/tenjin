# frozen_string_literal: true

module System
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    layout "system"

    private

    # Prepend the :system namespace symbol so Pundit resolves
    # System::FooPolicy instead of FooPolicy. Call sites stay unchanged
    # (`authorize @school`, `policy_scope(School)`).
    def authorize(record, query = nil, policy_class: nil)
      super([:system, record], query, policy_class: policy_class)
    end

    def policy_scope(scope, policy_scope_class: nil)
      super([:system, scope], policy_scope_class: policy_scope_class)
    end

    def policy(record)
      super([:system, record])
    end

    def pundit_user
      current_admin
    end
  end
end
