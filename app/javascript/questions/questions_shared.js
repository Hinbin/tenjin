export default function updateQuizStatistics (serverResponse) {
  const { multiplier, answeredCorrect, streak } = serverResponse
  const mulEl = document.getElementById('multiplier')
  const acEl = document.getElementById('answeredCorrect')
  const stEl = document.getElementById('streak')
  if (mulEl) mulEl.textContent = multiplier
  if (acEl) acEl.textContent = answeredCorrect
  if (stEl) stEl.textContent = streak
}
