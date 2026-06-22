import { submitAnswer, finishAnswer, revealFeedback, submitOnEnter } from 'questions/questions_shared'

// Matrix (tick-box grid) quiz question. Collect ticked cells as { row_id => [col_id, …] },
// PUT them, then reveal the correct cells. Partial-credit scored on the server.

function tickedAnswer () {
  const answer = {}
  document.querySelectorAll('#matrix input[type=checkbox]:checked').forEach(box => {
    (answer[box.dataset.row] ||= []).push(box.dataset.col)
  })
  return answer
}

// Mark the answer key directly rather than by match/mismatch: every cell that NEEDED a tick goes
// green with a ✓ (so the correct selection is explicit), and any tick the student added where one
// wasn't wanted goes red with a ✗. Cells that were correctly left blank stay neutral — this avoids
// the confusing "empty cell is green because you correctly didn't tick it" double-negative.
function revealMatrix (serverResponse) {
  const solution = serverResponse.solution || {}
  document.querySelectorAll('#matrix .tjs-matrix__cell').forEach(cell => {
    const box = cell.querySelector('input[type=checkbox]')
    const shouldTick = (solution[box.dataset.row] || []).includes(box.dataset.col)
    if (shouldTick) {
      cell.classList.add('tjs-matrix__cell--required')
      // Required but left unticked — a tick the student missed.
      if (!box.checked) cell.classList.add('tjs-matrix__cell--missed')
    } else if (box.checked) {
      // A tick the student added in a cell that should be empty.
      cell.classList.add('tjs-matrix__cell--wrong')
    }
  })
}

submitOnEnter('matrixSubmit')

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
    // Required cells are marked green inline (.tjs-matrix__cell--required); add the explanation.
    revealFeedback(null, result.explanation, result.tooFast)
    finishAnswer(result.score >= 1.0, result)
  })
})
