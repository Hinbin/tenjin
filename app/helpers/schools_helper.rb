# frozen_string_literal: true

module SchoolsHelper
  # rubocop:disable Metrics/MethodLength
  def sync_status_icon(status)
    case status
    when 'queued'
      "<i class='fas fa-clock'></i>".html_safe
    when 'syncing'
      "<i class='fas fa-sync'></i>".html_safe
    when 'successful'
      "<i class='fas fa-check' style='color:green'></i>".html_safe
    when 'failed'
      "<i class='fas fa-times' style='color:red'></i>".html_safe
    when 'needed'
      "<i class='fas fa-exclamation-triangle' style='color:red'></i>".html_safe
    else
      "<i class='fas fa-question' style='color:red'></i>".html_safe
    end
  end
  # rubocop:enable Metrics/MethodLength
end
