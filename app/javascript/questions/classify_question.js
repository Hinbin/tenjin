import { submitAnswer, finishAnswer, revealFeedback, submitOnEnter } from 'questions/questions_shared'

// Classify question — drag item tiles from the source tray into named .tjs-bucket drop zones, then
// #classifySubmit PUTs { item_id => target_id } and reveals the correct placement.
// Unlike drag_drop (cloze), each tile is a single-use unit: it moves rather than clones.
//
// Interaction modes (both active simultaneously):
//   Drag — standard HTML5 drag + touch_drag.js shim. Works on desktop and most Android.
//   Tap  — tap a tile to select it, then tap a bucket (or the tray) to place it. Designed for
//           mobile where the bucket may be off-screen during a drag gesture.

// ── Helpers ─────────────────────────────────────────────────────────────────

function bucketBody (bucket) {
  return bucket.querySelector('.tjs-bucket__body') || bucket
}

function placedAnswer () {
  const answer = {}
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    bucketBody(bucket).querySelectorAll('.tjs-tile').forEach(tile => {
      answer[tile.dataset.itemId] = bucket.dataset.targetId
    })
  })
  return answer
}

function targetLabelMap () {
  const map = {}
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    const label = bucket.querySelector('.tjs-bucket__label')
    if (label) map[bucket.dataset.targetId] = label.textContent.trim()
  })
  return map
}

// Show the hint in a bucket only when it has no tiles.
function syncHints () {
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    const body = bucketBody(bucket)
    const hint = bucket.querySelector('.tjs-bucket__hint')
    if (!hint) return
    hint.style.display = body.querySelector('.tjs-tile') ? 'none' : ''
  })
}

// ── Reveal ───────────────────────────────────────────────────────────────────

function revealClassify (serverResponse) {
  const solution = serverResponse.solution || {}
  const labels = targetLabelMap()
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    bucketBody(bucket).querySelectorAll('.tjs-tile').forEach(tile => {
      const correctTargetId = solution[tile.dataset.itemId]
      const correct = correctTargetId === bucket.dataset.targetId
      tile.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
      if (!correct && correctTargetId) {
        const tag = document.createElement('span')
        tag.className = 'tjs-slot__correct'
        tag.textContent = labels[correctTargetId] || correctTargetId
        tile.insertAdjacentElement('afterend', tag)
      }
    })
  })
  document.querySelectorAll('#classify [data-source] .tjs-tile').forEach(tile => {
    tile.classList.add('incorrect-answer')
  })
}

// ── Drag (mouse + touch_drag shim) ──────────────────────────────────────────

function dropZones () {
  return document.querySelectorAll('#classify .tjs-bucket, #classify [data-source]')
}

function clearDragState () {
  dropZones().forEach(zone => zone.classList.remove('tjs-drop-active', 'tjs-drop-over'))
}

let dragFromZone = null

document.addEventListener('dragstart', (event) => {
  const tile = event.target.closest('#classify .tjs-draggable')
  if (!tile) return
  dragFromZone = tile.parentElement.closest('.tjs-bucket, [data-source]')
  event.dataTransfer.setData('text/plain', tile.dataset.itemId)
  tile.classList.add('tjs-dragging')
  dropZones().forEach(zone => zone.classList.add('tjs-drop-active'))
})

document.addEventListener('dragend', (event) => {
  event.target.closest?.('#classify .tjs-draggable')?.classList.remove('tjs-dragging')
  dragFromZone = null
  clearDragState()
})

document.addEventListener('dragover', (event) => {
  const zone = event.target.closest('#classify .tjs-bucket, #classify [data-source]')
  if (!zone) return
  event.preventDefault()
  dropZones().forEach(z => z.classList.toggle('tjs-drop-over', z === zone))
})

document.addEventListener('drop', (event) => {
  const bucket = event.target.closest('#classify .tjs-bucket')
  const tray   = event.target.closest('#classify [data-source]')
  if (!bucket && !tray) return
  event.preventDefault()

  const itemId = event.dataTransfer.getData('text/plain')
  const tile = document.querySelector(`#classify .tjs-tile[data-item-id="${itemId}"]`)
  if (!tile) return

  if (bucket) {
    bucketBody(bucket).appendChild(tile)
  } else if (tray) {
    tray.appendChild(tile)
  }
  tile.classList.remove('tjs-dragging')
  dragFromZone = null
  clearDragState()
  syncHints()
})

// ── Tap-to-place ─────────────────────────────────────────────────────────────
// Tap a tile → it becomes selected. Tap a bucket or the tray → move tile there.
// Tap the selected tile again → deselect. Works alongside drag with no conflict.

let selectedTile = null

function clearTapSelection () {
  if (selectedTile) selectedTile.classList.remove('tjs-tile--selected')
  selectedTile = null
  document.querySelectorAll('#classify .tjs-bucket').forEach(b => b.classList.remove('tjs-bucket--tap-target'))
}

function selectTile (tile) {
  clearTapSelection()
  selectedTile = tile
  tile.classList.add('tjs-tile--selected')
  document.querySelectorAll('#classify .tjs-bucket').forEach(b => b.classList.add('tjs-bucket--tap-target'))
}

document.addEventListener('click', (event) => {
  // Submit button — handled separately below.
  if (event.target.closest('#classifySubmit')) return

  const tile = event.target.closest('#classify .tjs-draggable')
  const bucket = event.target.closest('#classify .tjs-bucket')
  const tray = event.target.closest('#classify [data-source]')

  if (tile) {
    // Tapping the already-selected tile deselects.
    if (tile === selectedTile) { clearTapSelection(); return }
    selectTile(tile)
    return
  }

  if (!selectedTile) return

  if (bucket) {
    bucketBody(bucket).appendChild(selectedTile)
    clearTapSelection()
    syncHints()
    return
  }

  if (tray) {
    tray.appendChild(selectedTile)
    clearTapSelection()
    syncHints()
  }
})

// ── Submit ───────────────────────────────────────────────────────────────────

submitOnEnter('classifySubmit')

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#classifySubmit')
  if (!btn || btn.hasAttribute('disabled')) return
  clearTapSelection()
  btn.setAttribute('disabled', 'disabled')
  document.querySelectorAll('#classify .tjs-draggable').forEach(t => { t.draggable = false })

  const answer = placedAnswer()
  const params = {}
  Object.entries(answer).forEach(([itemId, targetId]) => { params[`answer[structured][${itemId}]`] = targetId })
  submitAnswer(params).then(result => {
    revealClassify(result)
    revealFeedback(null, result.explanation, result.tooFast)
    finishAnswer(result.score >= 1.0, result)
  })
})

syncHints()
