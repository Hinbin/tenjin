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

// Anti-cheat: shown when the server rejected the answer's speed (tooFast) — see Quiz::CheckAnswer.
export const TOO_FAST_MESSAGE = 'Answered too fast to count — no points awarded for this question.'

// Post-answer learning panel (#answerFeedback, present in every quiz partial). `correctNode` is an
// optional DOM node spelling out the correct answer for types that can't show it inline (short answer,
// ordering); `explanation` is the author's optional "why" from the question; `tooFast` shows the
// no-points speed warning. We only reveal the panel when there's something to say, so a clean correct
// answer with no explanation stays uncluttered.
// Built with textContent / DOM nodes — never innerHTML — so author text can't inject markup.
export function revealFeedback (correctNode, explanation, tooFast = false) {
  const el = document.getElementById('answerFeedback')
  if (!el) return
  el.replaceChildren()

  if (tooFast) {
    const warn = document.createElement('p')
    warn.className = 'tjs-quiz__feedback-warning'
    warn.textContent = TOO_FAST_MESSAGE
    el.appendChild(warn)
  }
  if (correctNode) el.appendChild(correctNode)
  if (explanation && String(explanation).trim()) {
    const p = document.createElement('p')
    p.className = 'tjs-quiz__feedback-why'
    p.textContent = explanation
    el.appendChild(p)
  }

  if (el.childElementCount > 0) el.classList.remove('tj-hidden')
}

// A "Correct answer: …" line for the feedback panel. `label` lets callers say e.g. "Correct order".
export function correctAnswerNode (text, label = 'Correct answer') {
  const wrap = document.createElement('p')
  wrap.className = 'tjs-quiz__feedback-answer'
  const tag = document.createElement('span')
  tag.className = 'tjs-quiz__feedback-label'
  tag.textContent = `${label}: `
  wrap.append(tag, document.createTextNode(text))
  return wrap
}

// Wire Enter to "Check Answer" so keyboard users can answer without reaching for the mouse. Once the
// answer is in, the question's submit button is disabled and #nextButton takes focus — we bail on the
// disabled (or absent) button so Enter then activates Next natively. Shift+Enter and Enter inside a
// textarea are left alone so they can still insert a newline.
export function submitOnEnter (submitButtonId) {
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter' || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey) return
    if (event.target.tagName === 'TEXTAREA') return
    const btn = document.getElementById(submitButtonId)
    if (!btn || btn.hasAttribute('disabled')) return
    event.preventDefault()
    btn.click()
  })
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
