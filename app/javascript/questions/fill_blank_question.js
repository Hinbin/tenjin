import { submitAnswer, finishAnswer, revealFeedback } from 'questions/questions_shared'

// Gap-fill (typed cloze) quiz question. Type a word into each .tjs-blank, then #fillBlankSubmit PUTs
// { slot => typed text } and reveals which blanks were right. Scoring is partial-credit on the server
// (Question#score_response), which matches case-insensitively against the accepted answers.

function typedAnswer () {
  const answer = {}
  document.querySelectorAll('#fillBlank .tjs-blank').forEach(input => {
    answer[input.dataset.slot] = input.value
  })
  return answer
}

// The solution maps slot => accepted answer string ("a|b" alternatives). Mark a blank correct when the
// typed text matches any alternative (trimmed, case-insensitive) — mirrors the server scoring.
function revealFillBlank (serverResponse) {
  const solution = serverResponse.solution || {}
  document.querySelectorAll('#fillBlank .tjs-blank').forEach(input => {
    const accepted = String(solution[input.dataset.slot] || '').split('|').map(s => s.trim()).filter(Boolean)
    const given = input.value.trim()
    const correct = accepted.some(a => a.toLowerCase() === given.toLowerCase())
    input.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
    // Leave the student's typed answer in place (marked wrong) and show the correct word next to it,
    // so they can compare their attempt against the answer rather than having it overwritten.
    if (!correct && accepted.length) {
      const tag = document.createElement('span')
      tag.className = 'tjs-blank__correct'
      tag.textContent = accepted[0]
      input.insertAdjacentElement('afterend', tag)
    }
  })
}

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#fillBlankSubmit')
  if (!btn || btn.hasAttribute('disabled')) return
  btn.setAttribute('disabled', 'disabled')
  document.querySelectorAll('#fillBlank .tjs-blank').forEach(i => { i.readOnly = true })

  const answer = typedAnswer()
  const params = {}
  Object.entries(answer).forEach(([slot, text]) => { params[`answer[structured][${slot}]`] = text })
  submitAnswer(params).then(result => {
    revealFillBlank(result)
    revealFeedback(null, result.explanation)
    finishAnswer(result.score >= 1.0, result)
  })
})
