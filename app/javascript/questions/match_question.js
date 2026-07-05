import { submitAnswer, finishAnswer, revealFeedback, submitOnEnter } from 'questions/questions_shared'

// Match question — pair each left keyword with its right definition ("draw a line"). Tap a keyword to
// select it, then tap a definition to connect them; each pairing gets a stable colour + number badge
// on both ends, and on wide screens we also draw an SVG connector line between them. The line is a
// visual layer only — when the layout stacks on narrow screens the CSS hides the overlay and the badge
// alone carries the pairing, so the question is fully answerable by tap on a phone. Strictly 1:1:
// re-pairing a keyword replaces its link, and re-using a definition steals it from its previous keyword.
//
// Submit PUTs { left_id => right_id } and the server reveals the correct mapping; scoring is
// partial-credit on the server (Question#score_response). Presentation aside, this mirrors classify.

const PAIR_VARS = ['--tjs-match-p1', '--tjs-match-p2', '--tjs-match-p3', '--tjs-match-p4', '--tjs-match-p5']

let selectedLeft = null
let answered = false
const pairs = {}        // left_id => right_id (the student's connections)
const colorIndex = {}   // left_id => palette index — stable per keyword by its column order
const badgeNumber = {}  // left_id => 1-based number shown in the badge

function root () { return document.getElementById('match') }
function leftNodes () { return Array.from(document.querySelectorAll('#match .tjs-match__item')) }
function leftNode (id) { return document.querySelector(`#match .tjs-match__item[data-left-id="${id}"]`) }
function rightNode (id) { return document.querySelector(`#match .tjs-match__option[data-right-id="${id}"]`) }
function linesSvg () { return document.querySelector('#match .tjs-match__lines') }

// Give each keyword a fixed colour + number by its column order, so a pairing keeps the same look no
// matter which definition it lands on.
function indexNodes () {
  leftNodes().forEach((node, i) => {
    const id = node.dataset.leftId
    colorIndex[id] = i % PAIR_VARS.length
    badgeNumber[id] = i + 1
  })
}

// right_id => definition text, so the reveal can name the correct definition for a missed keyword.
function rightTextMap () {
  const map = {}
  document.querySelectorAll('#match .tjs-match__option').forEach(node => {
    map[node.dataset.rightId] = node.querySelector('.tjs-match__text').textContent.trim()
  })
  return map
}

function clearSelection () {
  selectedLeft = null
  document.querySelectorAll('#match .is-selected').forEach(node => node.classList.remove('is-selected'))
}

// Repaint every node from `pairs`: colour + badge on each paired end, then redraw the connector lines.
function renderPairs () {
  document.querySelectorAll('#match .tjs-match__node').forEach(node => {
    node.classList.remove('is-paired')
    node.style.removeProperty('--pair')
    node.querySelector('.tjs-match__badge').textContent = ''
  })
  Object.entries(pairs).forEach(([leftId, rightId]) => {
    [leftNode(leftId), rightNode(rightId)].forEach(node => {
      if (!node) return
      node.classList.add('is-paired')
      node.style.setProperty('--pair', `var(${PAIR_VARS[colorIndex[leftId]]})`)
      node.querySelector('.tjs-match__badge').textContent = badgeNumber[leftId]
    })
  })
  drawLines()
}

// Draw one curved connector per pairing, from the keyword's right edge to the definition's left edge.
// Coordinates are relative to the .tjs-match__cols box the SVG overlays exactly (inset:0, no viewBox),
// so a bounding-rect delta maps 1:1 to SVG user units. Skipped entirely when the overlay is hidden —
// the stacked (mobile) layout sets it display:none, and the number badge carries the pairing there.
function drawLines () {
  const svg = linesSvg()
  if (!svg) return
  while (svg.firstChild) svg.removeChild(svg.firstChild)
  if (getComputedStyle(svg).display === 'none') return

  const base = svg.parentElement.getBoundingClientRect()
  Object.entries(pairs).forEach(([leftId, rightId]) => {
    const ln = leftNode(leftId)
    const rn = rightNode(rightId)
    if (!ln || !rn) return
    const lr = ln.getBoundingClientRect()
    const rr = rn.getBoundingClientRect()
    const x1 = lr.right - base.left
    const y1 = lr.top + lr.height / 2 - base.top
    const x2 = rr.left - base.left
    const y2 = rr.top + rr.height / 2 - base.top
    const midX = (x1 + x2) / 2
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
    path.setAttribute('d', `M ${x1} ${y1} C ${midX} ${y1}, ${midX} ${y2}, ${x2} ${y2}`)
    path.setAttribute('fill', 'none')
    path.setAttribute('stroke', `var(${PAIR_VARS[colorIndex[leftId]]})`)
    path.setAttribute('stroke-width', '2.5')
    path.setAttribute('stroke-linecap', 'round')
    path.setAttribute('opacity', '0.85')
    svg.appendChild(path)
  })
}

function selectLeft (id) {
  if (answered) return
  if (selectedLeft === id) { clearSelection(); return }
  clearSelection()
  selectedLeft = id
  leftNode(id)?.classList.add('is-selected')
}

function pairRight (rightId) {
  if (answered) return
  // Whoever currently owns this definition (1:1 on the right — a definition answers one keyword).
  const owner = Object.keys(pairs).find(leftId => pairs[leftId] === rightId)
  if (!selectedLeft) {
    // Tapping a linked definition with nothing selected clears its pairing.
    if (owner) { delete pairs[owner]; renderPairs() }
    return
  }
  if (owner && owner !== selectedLeft) delete pairs[owner] // steal it from its previous keyword
  pairs[selectedLeft] = rightId                            // 1:1 on the left — replaces any old link
  clearSelection()
  renderPairs()
}

// Reveal: mark each keyword (and the definition it chose) correct/incorrect against the server key, and
// for a miss drop the correct definition's text beside the keyword — the student's wrong pick stays.
function revealMatch (serverResponse) {
  const solution = serverResponse.solution || {}
  const text = rightTextMap()
  leftNodes().forEach(ln => {
    const leftId = ln.dataset.leftId
    const chosen = pairs[leftId]
    const correctRightId = solution[leftId]
    const correct = chosen && chosen === correctRightId
    ln.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
    if (chosen) rightNode(chosen)?.classList.add(correct ? 'correct-answer' : 'incorrect-answer')
    if (!correct && correctRightId) {
      const tag = document.createElement('span')
      tag.className = 'tjs-slot__correct'
      tag.textContent = text[correctRightId] || ''
      ln.insertAdjacentElement('afterend', tag)
    }
  })
  drawLines()
}

// Fresh state each time the question mounts (Next reloads the page, but guard against double-binding).
function init () {
  if (!root()) return
  selectedLeft = null
  answered = false
  Object.keys(pairs).forEach(key => delete pairs[key])
  indexNodes()
  renderPairs()
}

document.addEventListener('turbo:load', init)
document.addEventListener('DOMContentLoaded', init)
window.addEventListener('resize', drawLines)

submitOnEnter('matchSubmit')

document.addEventListener('click', (event) => {
  const leftBtn = event.target.closest('#match .tjs-match__item')
  if (leftBtn) { selectLeft(leftBtn.dataset.leftId); return }
  const rightBtn = event.target.closest('#match .tjs-match__option')
  if (rightBtn) { pairRight(rightBtn.dataset.rightId); return }

  const submit = event.target.closest('#matchSubmit')
  if (!submit || submit.hasAttribute('disabled')) return
  submit.setAttribute('disabled', 'disabled')
  answered = true
  clearSelection()

  const params = {}
  Object.entries(pairs).forEach(([leftId, rightId]) => { params[`answer[structured][${leftId}]`] = rightId })
  submitAnswer(params).then(result => {
    revealMatch(result)
    revealFeedback(null, result.explanation, result.tooFast)
    finishAnswer(result.score >= 1.0, result)
  })
})
