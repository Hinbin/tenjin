import { submitAnswer, finishAnswer } from 'questions/questions_shared'

// Drag-and-drop (cloze) quiz question. Drag .tjs-draggable item tiles into .tjs-slot blanks, then
// #dragDropSubmit PUTs { slot => item_id } and reveals the correct mapping. Presentation aside, all
// scoring is partial-credit on the server (Question#score_response).

function placedAnswer () {
  const answer = {}
  document.querySelectorAll('#dragDrop .tjs-slot').forEach(slot => {
    const tile = slot.querySelector('.tjs-tile')
    if (tile) answer[slot.dataset.slot] = tile.dataset.itemId
  })
  return answer
}

function revealDragDrop (serverResponse) {
  const solution = serverResponse.solution || {}
  document.querySelectorAll('#dragDrop .tjs-slot').forEach(slot => {
    const tile = slot.querySelector('.tjs-tile')
    const correctId = solution[slot.dataset.slot]
    const correct = tile && tile.dataset.itemId === correctId
    slot.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
  })
}

function dragStart (event) {
  const tile = event.target.closest('.tjs-draggable')
  if (!tile) return
  event.dataTransfer.setData('text/plain', tile.dataset.itemId)
  tile.classList.add('tjs-dragging')
}

function dropOnTarget (event) {
  const target = event.target.closest('.tjs-slot, [data-tray]')
  if (!target) return
  event.preventDefault()
  const itemId = event.dataTransfer.getData('text/plain')
  const tile = document.querySelector(`#dragDrop .tjs-tile[data-item-id="${itemId}"]`)
  if (!tile) return
  // A slot holds one tile: bounce any current occupant back to the tray.
  if (target.classList.contains('tjs-slot')) {
    const occupant = target.querySelector('.tjs-tile')
    if (occupant) document.querySelector('#dragDrop [data-tray]')?.appendChild(occupant)
  }
  target.appendChild(tile)
}

document.addEventListener('dragstart', dragStart)
document.addEventListener('dragend', (e) => e.target.closest?.('.tjs-draggable')?.classList.remove('tjs-dragging'))
document.addEventListener('dragover', (e) => { if (e.target.closest('#dragDrop .tjs-slot, #dragDrop [data-tray]')) e.preventDefault() })
document.addEventListener('drop', dropOnTarget)

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#dragDropSubmit')
  if (!btn || btn.hasAttribute('disabled')) return
  btn.setAttribute('disabled', 'disabled')
  document.querySelectorAll('#dragDrop .tjs-draggable').forEach(t => { t.draggable = false })

  const answer = placedAnswer()
  const params = {}
  Object.entries(answer).forEach(([slot, itemId]) => { params[`answer[structured][${slot}]`] = itemId })
  submitAnswer(params).then(result => {
    revealDragDrop(result)
    finishAnswer(result.score >= 1.0, result)
  })
})
