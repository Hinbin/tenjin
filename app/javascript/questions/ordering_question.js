import { submitAnswer, finishAnswer, revealFeedback } from 'questions/questions_shared'

// Ordering (sequencing) quiz question. Drag .tjs-order-item tiles to reorder them (or nudge with the
// ↑/↓ buttons), then #orderingSubmit PUTs the current order as a list of item ids and reveals which
// tiles ended up in the right position. Partial-credit scored on the server (Question#score_response).

function currentOrder () {
  return Array.from(document.querySelectorAll('#ordering .tjs-order-item')).map(item => item.dataset.itemId)
}

function move (button, delta) {
  const item = button.closest('.tjs-order-item')
  const list = item.parentElement
  if (delta < 0 && item.previousElementSibling) {
    list.insertBefore(item, item.previousElementSibling)
  } else if (delta > 0 && item.nextElementSibling) {
    list.insertBefore(item.nextElementSibling, item)
  }
}

// ── Drag to reorder ─────────────────────────────────────────────────────────
let draggingItem = null

// The tile to drop BEFORE: the first un-dragged tile whose vertical midpoint is below the cursor.
// null means the cursor is past the last tile, so append to the end.
function dropTarget (list, y) {
  const tiles = Array.from(list.querySelectorAll('.tjs-order-item:not(.tjs-dragging)'))
  return tiles.find(tile => {
    const box = tile.getBoundingClientRect()
    return y < box.top + box.height / 2
  }) || null
}

document.addEventListener('dragstart', (event) => {
  const item = event.target.closest('#ordering .tjs-order-item')
  if (!item || item.draggable === false) return
  draggingItem = item
  item.classList.add('tjs-dragging')
  event.dataTransfer.effectAllowed = 'move'
})

document.addEventListener('dragend', () => {
  draggingItem?.classList.remove('tjs-dragging')
  draggingItem = null
})

// Reorder live as the tile is dragged over the list so the drop position is always visible.
document.addEventListener('dragover', (event) => {
  if (!draggingItem) return
  const list = document.getElementById('orderingList')
  if (!list || !list.contains(event.target)) return
  event.preventDefault()
  const before = dropTarget(list, event.clientY)
  if (before) list.insertBefore(draggingItem, before)
  else list.appendChild(draggingItem)
})

// Reveal: solution is the correct list of item ids. Scoring is adjacency-based, so highlight tiles
// that sit in a correct consecutive PAIR (a tile is green when it's correctly linked to the tile
// before or after it). This matches the score: a perfect order lights every tile, a reversed order
// lights none.
function revealOrdering (serverResponse) {
  const solution = serverResponse.solution || []
  const items = Array.from(document.querySelectorAll('#ordering .tjs-order-item'))
  const given = items.map(item => item.dataset.itemId)
  const linked = new Array(items.length).fill(false)

  for (let i = 0; i < given.length - 1; i++) {
    const keyIndex = solution.indexOf(given[i])
    if (keyIndex !== -1 && solution[keyIndex + 1] === given[i + 1]) {
      linked[i] = true
      linked[i + 1] = true
    }
  }

  items.forEach((item, i) => item.classList.add(linked[i] ? 'correct-answer' : 'incorrect-answer'))
}

// Their tiles stay in the order they chose (marked by adjacency); the correct sequence can't be shown
// inline, so build an ordered list of it for the feedback panel — but only when they didn't get it all.
function correctOrderNode (serverResponse) {
  if (serverResponse.score >= 1.0) return null
  const solution = serverResponse.solution || []
  const text = {}
  document.querySelectorAll('#ordering .tjs-order-item').forEach(item => {
    text[item.dataset.itemId] = item.querySelector('.tjs-order-item__text')?.textContent.trim() || ''
  })

  const heading = document.createElement('p')
  heading.className = 'tjs-quiz__feedback-label'
  heading.textContent = 'Correct order:'
  const list = document.createElement('ol')
  list.className = 'tjs-quiz__feedback-order'
  solution.forEach(id => {
    const li = document.createElement('li')
    li.textContent = text[id] || ''
    list.appendChild(li)
  })

  const wrap = document.createElement('div')
  wrap.className = 'tjs-quiz__feedback-answer'
  wrap.append(heading, list)
  return wrap
}

document.addEventListener('click', (event) => {
  const up = event.target.closest('#ordering .tjs-order-up')
  const down = event.target.closest('#ordering .tjs-order-down')
  if (up) { move(up, -1); return }
  if (down) { move(down, 1); return }

  const btn = event.target.closest('#orderingSubmit')
  if (!btn || btn.hasAttribute('disabled')) return
  btn.setAttribute('disabled', 'disabled')
  document.querySelectorAll('#ordering .tjs-order-up, #ordering .tjs-order-down').forEach(b => { b.disabled = true })
  document.querySelectorAll('#ordering .tjs-order-item').forEach(i => { i.draggable = false })

  const params = {}
  params['answer[structured][order][]'] = currentOrder()
  submitAnswer(params).then(result => {
    revealOrdering(result)
    revealFeedback(correctOrderNode(result), result.explanation)
    finishAnswer(result.score >= 1.0, result)
  })
})
