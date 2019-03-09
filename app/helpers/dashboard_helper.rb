module DashboardHelper
  def find_challenge_progress(challenge_progress, challenge)
    cp = challenge_progress.where(challenge: challenge).first
    return 0 if cp.nil?
    return icon('fas', 'check', style: 'color:green') if cp.completed == true

    progress = cp.progress
    return 0.to_s + '%' if progress.nil?

    progress.to_s + '%'
  end
end
