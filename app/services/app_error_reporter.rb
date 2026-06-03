# frozen_string_literal: true

class AppErrorReporter
  BACKTRACE_LIMIT = 30

  def self.report(exception, options = {})
    new(exception, options).report
  end

  def initialize(exception, options = {})
    @exception = exception
    @context = options.fetch(:context, {}).compact
    @request = options[:request]
    @user = options[:user] || warden_user(:user)
    @admin = options[:admin] || warden_user(:admin)
    @job = options[:job]
  end

  def report
    AppError.create!(attributes)
  rescue StandardError => e
    Rails.logger.error("AppErrorReporter failed: #{e.class} #{e.message}")
    nil
  end

  private

  def attributes
    { exception_class: @exception.class.name,
      message: @exception.message,
      backtrace: Array(@exception.backtrace).first(BACKTRACE_LIMIT).join("\n"),
      environment: Rails.env,
      context: @context }.merge(request_attributes, actor_attributes, job_attributes)
  end

  def request_attributes
    { request_id: request_id,
      controller: request_params['controller'],
      action: request_params['action'],
      url: @request&.fullpath,
      params: filtered_params }
  end

  def actor_attributes
    { user_id: @user&.id,
      admin_id: @admin&.id }
  end

  def job_attributes
    { job_class: @job&.class&.name,
      job_id: @job&.job_id }
  end

  def request_id
    @request&.request_id || @request&.env&.fetch('action_dispatch.request_id', nil)
  end

  def filtered_params
    parameter_filter.filter(request_params)
  rescue StandardError
    {}
  end

  def request_params
    @request&.filtered_parameters || {}
  end

  def parameter_filter
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  end

  def warden_user(scope)
    return unless @request

    warden = @request.env.fetch('warden', nil)
    warden&.user(scope)
  rescue StandardError
    nil
  end
end
