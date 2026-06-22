// Dashboard quiz-start guard. A topic/challenge/homework row starts a quiz, but we first consult the
// state rendered on .tjs-dashboard (data-cooldown-until / data-active-quiz-*) so we never silently
// drop the user back into an old quiz or lose its progress. Four cases:
//   on cooldown + active quiz → offer to resume it (can't start a new one yet)
//   on cooldown + no quiz     → tell them to wait N seconds
//   ready      + active quiz  → warn that starting a new quiz loses the old one's progress
//   ready      + no quiz      → just start
document.addEventListener('turbo:load', () => {
  document.querySelectorAll('.challenge-row, .homework-row, .topic-row').forEach(row => {
    row.addEventListener('click', (event) => guardedStart(event.currentTarget))
  })
})

function dashboardState () {
  const ds = document.querySelector('.tjs-dashboard')?.dataset || {}
  const until = Number(ds.cooldownUntil || 0)
  return {
    secondsLeft: until ? Math.max(0, Math.ceil((until - Date.now()) / 1000)) : 0,
    activeQuizId: ds.activeQuizId || '',
    activeTopic: ds.activeQuizTopic || 'current'
  }
}

function guardedStart (row) {
  const { secondsLeft, activeQuizId, activeTopic } = dashboardState()
  const onCooldown = secondsLeft > 0
  const hasActive = Boolean(activeQuizId)
  const resume = () => Turbo.visit('/quizzes/' + activeQuizId)
  const startNew = () => { row.disabled = true; startQuiz(row) }

  if (onCooldown && hasActive) {
    openDialog(`You can start a new quiz in ${secondsLeft}s. Carry on with your current ${activeTopic} quiz instead?`,
      [{ label: 'Resume quiz', primary: true, action: resume }, { label: 'Cancel' }])
  } else if (onCooldown) {
    openDialog(`Hold on — you can start a new quiz in ${secondsLeft}s.`, [{ label: 'OK', primary: true }])
  } else if (hasActive) {
    openDialog(`Starting a new quiz will end your current ${activeTopic} quiz and you'll lose its progress.`,
      [{ label: 'Start new quiz', primary: true, action: startNew },
        { label: 'Resume current', action: resume },
        { label: 'Cancel' }])
  } else {
    startNew()
  }
}

function startQuiz (row) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  const params = new URLSearchParams({
    'quiz[subject]': row.dataset.subject,
    'quiz[topic_id]': row.dataset.topic
  })
  if (row.dataset.lesson) params.append('quiz[lesson_id]', row.dataset.lesson)
  fetch('/quizzes', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRF-Token': csrfToken
    },
    body: params
  }).then(() => Turbo.visit('/quizzes'))
}

// Builds a one-off <dialog> matching the shared alert-modal styling (.tj-dialog-*). Each button runs
// its optional action then closes; the dialog is removed on close.
function openDialog (message, buttons) {
  const dialog = document.createElement('dialog')
  const footer = buttons.map((_, i) =>
    `<button type="button" data-index="${i}" class="${buttons[i].primary ? 'tjs-btn tjs-btn--primary' : 'tj-btn-secondary'}">${buttons[i].label}</button>`
  ).join('')
  dialog.innerHTML =
    `<div class="tj-dialog-content"><div class="tj-dialog-body"><p>${message}</p></div>` +
    `<div class="tj-dialog-footer">${footer}</div></div>`
  dialog.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => {
      dialog.close()
      buttons[Number(btn.dataset.index)].action?.()
    })
  })
  dialog.addEventListener('close', () => dialog.remove())
  document.body.appendChild(dialog)
  dialog.showModal()
}
