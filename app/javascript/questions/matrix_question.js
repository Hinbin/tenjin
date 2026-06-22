import { submitAnswer, finishAnswer, revealFeedback } from 'questions/questions_shared'

// Matrix (tick-box grid) quiz question. Collect ticked cells as { row_id => [col_id, …] },
// PUT them, then reveal the correct cells. Partial-credit scored on the server.

function tickedAnswer () {
  const answer = {}
  document.querySelectorAll('#matrix input[type=checkbox]:checked').forEach(box => {
    (answer[box.dataset.row] ||= []).push(box.dataset.col)
  })
  return answer
}

function revealMatrix (serverResponse) {
  const solution = serverResponse.solution || {}
  document.querySelectorAll('#matrix .tjs-matrix__cell').forEach(cell => {
    const box = cell.querySelector('input[type=checkbox]')
    const shouldTick = (solution[box.dataset.row] || []).includes(box.dataset.col)
    const matches = box.checked === shouldTick
    cell.classList.add(matches ? 'correct-answer' : 'incorrect-answer')
    if (shouldTick) cell.classList.add('tjs-matrix__cell--key')
  })
}

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#matrixSubmit')
  if (!btn || btn.hasAttribute('disabled')) return
  btn.setAttribute('disabled', 'disabled')
  document.querySelectorAll('#matrix input[type=checkbox]').forEach(b => { b.disabled = true })

  const answer = tickedAnswer()
  const params = {}
  Object.entries(answer).forEach(([rowId, cols]) => { params[`answer[structured][${rowId}][]`] = cols })
  submitAnswer(params).then(result => {
    revealMatrix(result)
    // Correct cells are keyed inline (.tjs-matrix__cell--key); add the author's explanation.
    revealFeedback(null, result.explanation)
    finishAnswer(result.score >= 1.0, result)
  })
})
