module SchoolsHelper
  def sync_status_icon(status)
    case status
    when 'in progress'
      icon('fas', 'sync')
    when 'successful'
      icon('fas', 'check', style: 'color:green')
    when 'failed'
      icon('fas', 'times', style: 'color:red')
    else
      icon('fas', 'question')
    end
  end

end
