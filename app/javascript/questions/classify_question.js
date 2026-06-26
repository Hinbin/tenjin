import { submitAnswer, finishAnswer, revealFeedback, submitOnEnter } from 'questions/questions_shared'

// Classify question — drag item tiles from the source tray into named .tjs-bucket drop zones, then
// #classifySubmit PUTs { item_id => target_id } and reveals the correct placement.
// Unlike drag_drop (cloze), each tile is a single-use unit: it moves rather than clones.

function placedAnswer () {
  const answer = {}
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    bucket.querySelectorAll('.tjs-tile').forEach(tile => {
      answer[tile.dataset.itemId] = bucket.dataset.targetId
    })
  })
  return answer
}

// target_id => label text, read from the bucket headings so the reveal can name the correct bucket.
function targetLabelMap () {
  const map = {}
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    const label = bucket.querySelector('.tjs-bucket__label')
    if (label) map[bucket.dataset.targetId] = label.textContent.trim()
  })
  return map
}

function revealClassify (serverResponse) {
  // solution is the config['correct'] map: { item_id => target_id }
  const solution = serverResponse.solution || {}
  const labels = targetLabelMap()
  document.querySelectorAll('#classify .tjs-bucket').forEach(bucket => {
    bucket.querySelectorAll('.tjs-tile').forEach(tile => {
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
  // Mark items still in the source tray (unplaced) as incorrect.
  document.querySelectorAll('#classify [data-source] .tjs-tile').forEach(tile => {
    tile.classList.add('incorrect-answer')
  })
}

// All valid drop targets: the named buckets and the source tray.
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
    bucket.appendChild(tile)
  } else if (tray) {
    tray.appendChild(tile)
  }
  tile.classList.remove('tjs-dragging')
  dragFromZone = null
  clearDragState()
})

submitOnEnter('classifySubmit')

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#classifySubmit')
  if (!btn || btn.hasAttribute('disabled')) return
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
