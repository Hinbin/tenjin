// Touch drag shim for the quiz drag questions (#dragDrop tiles, #ordering tiles).
//
// Native HTML5 drag-and-drop only kicks in on touch after the browser's own long-press
// (~half a second), which feels sluggish. This shim turns touch gestures on a draggable
// tile into the SAME dragstart → dragover → drop → dragend event sequence the desktop
// handlers already listen for, but starts as soon as the finger moves past a small
// threshold — no hold required. Desktop (mouse) drag is untouched: we only bind touch events.

// Treat a finger as "dragging" once it moves this many px from where it first touched down.
// Small enough to feel instant, large enough not to fire on an accidental tap.
const MOVE_THRESHOLD = 8

const CONTAINERS = '#dragDrop, #ordering'

let source = null      // the tile being dragged
let startX = 0
let startY = 0
let dragging = false
let transfer = null

// A stand-in for the native DataTransfer the handlers read/write (setData/getData/effectAllowed).
// The same instance is shared across one gesture's events so getData('text/plain') on drop
// returns what setData put there on dragstart.
function makeTransfer () {
  const store = {}
  return {
    effectAllowed: 'move',
    dropEffect: 'move',
    setData (key, value) { store[key] = String(value) },
    getData (key) { return store[key] || '' },
    setDragImage () {}
  }
}

// Dispatch a bubbling, cancelable event carrying the drag fields the handlers read. We use a
// plain Event with the fields defined on it rather than `new DragEvent(...)` so this works
// regardless of how a given browser handles the DragEvent constructor's dataTransfer init.
function fireDragEvent (type, target, x, y) {
  const event = new Event(type, { bubbles: true, cancelable: true })
  Object.defineProperties(event, {
    dataTransfer: { value: transfer },
    clientX: { value: x },
    clientY: { value: y }
  })
  target.dispatchEvent(event)
  return event
}

// The element under the finger, with the dragged tile ignored so we hit the drop zone beneath it.
function elementUnder (x, y) {
  const prev = source.style.pointerEvents
  source.style.pointerEvents = 'none'
  const el = document.elementFromPoint(x, y)
  source.style.pointerEvents = prev
  return el
}

function endDrag () {
  if (dragging) fireDragEvent('dragend', source, startX, startY)
  if (source) source.style.pointerEvents = ''
  source = null
  dragging = false
  transfer = null
}

document.addEventListener('touchstart', (event) => {
  if (event.touches.length !== 1) return
  const target = event.target
  // Don't hijack taps on the arrow buttons / links inside a tile.
  if (target.closest('button, a, input, [contenteditable]')) return
  const tile = target.closest('[draggable="true"]')
  if (!tile || !tile.closest(CONTAINERS) || tile.draggable === false) return

  source = tile
  dragging = false
  const touch = event.touches[0]
  startX = touch.clientX
  startY = touch.clientY
}, { passive: true })

document.addEventListener('touchmove', (event) => {
  if (!source) return
  const touch = event.touches[0]

  if (!dragging) {
    if (Math.hypot(touch.clientX - startX, touch.clientY - startY) < MOVE_THRESHOLD) return
    dragging = true
    transfer = makeTransfer()
    fireDragEvent('dragstart', source, touch.clientX, touch.clientY)
  }

  // Once dragging, swallow the scroll so the page doesn't slide under the tile.
  event.preventDefault()
  const over = elementUnder(touch.clientX, touch.clientY)
  if (over) fireDragEvent('dragover', over, touch.clientX, touch.clientY)
}, { passive: false })

document.addEventListener('touchend', (event) => {
  if (!source) return
  if (dragging) {
    const touch = event.changedTouches[0]
    const over = elementUnder(touch.clientX, touch.clientY)
    if (over) fireDragEvent('drop', over, touch.clientX, touch.clientY)
  }
  endDrag()
}, { passive: true })

document.addEventListener('touchcancel', endDrag, { passive: true })
