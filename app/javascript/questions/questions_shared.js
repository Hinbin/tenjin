export default function updateQuizStatistics (serverResponse) {
  const { multiplier, answeredCorrect, streak } = serverResponse
  const mulEl = document.getElementById('multiplier')
  const acEl = document.getElementById('answeredCorrect')
  const stEl = document.getElementById('streak')
  if (mulEl) mulEl.textContent = multiplier
  if (acEl) acEl.textContent = answeredCorrect
  if (stEl) stEl.textContent = streak
}

// PUT an answer payload to the current quiz path and resolve the parsed JSON. `params` is a flat
// object of URLSearchParams entries (nested keys like 'answer[structured][r1][]' are fine).
export function submitAnswer (params) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  const body = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (Array.isArray(value)) value.forEach(v => body.append(key, v))
    else body.append(key, value)
  }
  return fetch(window.location.pathname, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRF-Token': csrfToken,
      Accept: 'application/json'
    },
    body
  }).then(r => r.json())
}

// Notify quiz_controller (Stimulus) so it can run the reskinned flash / shake / combo juice, then
// reveal the Next button. Presentation only — scoring already happened on the server.
export function finishAnswer (correct, serverResponse) {
  updateQuizStatistics(serverResponse)
  document.dispatchEvent(new CustomEvent('quiz:answered', {
    detail: {
      correct,
      streak: serverResponse.streak,
      multiplier: serverResponse.multiplier,
      answeredCorrect: serverResponse.answeredCorrect
    }
  }))
  const nextBtn = document.getElementById('nextButton')
  if (nextBtn) {
    nextBtn.classList.remove('tj-invisible')
    nextBtn.focus()
  }
}
