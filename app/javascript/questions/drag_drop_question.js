import { submitAnswer, finishAnswer, revealFeedback, submitOnEnter } from 'questions/questions_shared'

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

// item_id => tile text, read from the tray originals, so the reveal can name the correct item.
function itemTextMap () {
  const map = {}
  document.querySelectorAll('#dragDrop [data-tray] .tjs-tile').forEach(tile => {
    map[tile.dataset.itemId] = tile.textContent.trim()
  })
  return map
}

function revealDragDrop (serverResponse) {
  const solution = serverResponse.solution || {}
  const text = itemTextMap()
  document.querySelectorAll('#dragDrop .tjs-slot').forEach(slot => {
    const tile = slot.querySelector('.tjs-tile')
    // A blank may accept several items, so the solution value can be a single id or an array of ids.
    const correctIds = [].concat(solution[slot.dataset.slot] || [])
    const correct = tile && correctIds.includes(tile.dataset.itemId)
    slot.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
    // Their dropped tile stays in the slot (marked wrong); name an accepted item right after it.
    const names = correctIds.map(id => text[id]).filter(Boolean)
    if (!correct && names.length) {
      const tag = document.createElement('span')
      tag.className = 'tjs-slot__correct'
      tag.textContent = names.join(' / ')
      slot.insertAdjacentElement('afterend', tag)
    }
  })
}

let dragFromSlot = null

// Every place the held tile could land: the blanks and the tray it returns to.
function dropZones () {
  return document.querySelectorAll('#dragDrop .tjs-slot, #dragDrop [data-tray]')
}

function clearDragState () {
  dropZones().forEach(zone => zone.classList.remove('tjs-drop-active', 'tjs-drop-over'))
}

function dragStart (event) {
  const tile = event.target.closest('.tjs-draggable')
  if (!tile) return
  // Remember whether the drag started from a slot (a placed copy) or the tray (a reusable original).
  dragFromSlot = tile.closest('.tjs-slot')
  event.dataTransfer.setData('text/plain', tile.dataset.itemId)
  tile.classList.add('tjs-dragging')
  // Light up every valid drop target so it's obvious where the tile can go.
  dropZones().forEach(zone => zone.classList.add('tjs-drop-active'))
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
  clearDragState()
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
document.addEventListener('dragend', (e) => {
  e.target.closest?.('.tjs-draggable')?.classList.remove('tjs-dragging')
  clearDragState()
})
// Highlight only the target currently under the cursor, so the student sees where the drop will land.
document.addEventListener('dragover', (event) => {
  const zone = event.target.closest('#dragDrop .tjs-slot, #dragDrop [data-tray]')
  if (!zone) return
  event.preventDefault()
  dropZones().forEach(z => z.classList.toggle('tjs-drop-over', z === zone))
})
document.addEventListener('drop', dropOnTarget)

submitOnEnter('dragDropSubmit')

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
    revealFeedback(null, result.explanation)
    finishAnswer(result.score >= 1.0, result)
  })
})
