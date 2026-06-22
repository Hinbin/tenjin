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

let dragFromSlot = null

function dragStart (event) {
  const tile = event.target.closest('.tjs-draggable')
  if (!tile) return
  // Remember whether the drag started from a slot (a placed copy) or the tray (a reusable original).
  dragFromSlot = tile.closest('.tjs-slot')
  event.dataTransfer.setData('text/plain', tile.dataset.itemId)
  tile.classList.add('tjs-dragging')
}

function dropOnTarget (event) {
  const slot = event.target.closest('#dragDrop .tjs-slot')
  const tray = event.target.closest('#dragDrop [data-tray]')
  if (!slot && !tray) return
  event.preventDefault()

  if (slot) {
    placeInSlot(slot, event.dataTransfer.getData('text/plain'))
  } else if (dragFromSlot) {
    // Dropping a placed copy back on the tray just removes it — the original tile stays available.
    dragFromSlot.querySelector('.tjs-tile')?.remove()
  }
  dragFromSlot = null
}

// Tray tiles are reusable originals, so an item can fill more than one blank: each drop drops a
// CLONE into the slot. A slot holds one tile; replace any existing occupant.
function placeInSlot (slot, itemId) {
  const original = document.querySelector(`#dragDrop [data-tray] .tjs-tile[data-item-id="${itemId}"]`)
  if (!original) return
  slot.querySelector('.tjs-tile')?.remove()
  const clone = original.cloneNode(true)
  clone.classList.remove('tjs-dragging')
  slot.appendChild(clone)
  if (dragFromSlot && dragFromSlot !== slot) dragFromSlot.querySelector('.tjs-tile')?.remove()
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
