module SchoolsHelper
  def sync_status_icon(status)
    case status
    when 'syncing'
      icon('fas', 'sync')
    when 'successful'
      icon('fas', 'check', style: 'color:green')
    when 'failed'
      icon('fas', 'times', style: 'color:red')
    when 'needed'
      icon('fas', 'exclamation-triangle', style: 'color:red' )
    else
      icon('fas', 'question')
    end
  end

end
