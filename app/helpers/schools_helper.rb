# frozen_string_literal: true

module SchoolsHelper
  # rubocop:disable Metrics/MethodLength
  def sync_status_icon(status)
    case status
    when 'queued'
      icon('fas', 'clock')
    when 'syncing'
      icon('fas', 'sync')
    when 'successful'
      icon('fas', 'check', style: 'color:green')
    when 'failed'
      icon('fas', 'times', style: 'color:red')
    when 'needed'
      icon('fas', 'exclamation-triangle', style: 'color:red')
    else
      icon('fas', 'question')
    end
  end
  # rubocop:enable Metrics/MethodLength
end
