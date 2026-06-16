import updateQuizStatistics from 'packs/questions/questions_shared'

function processMultipleChoiceResponse (serverResponse, guessId) {
  const results = serverResponse.answer
  let correct = false

  for (const result of results) {
    const resultEl = document.getElementById('response-' + result.id)
    if (resultEl) {
      resultEl.classList.add('correct-answer')
      if ('response-' + result.id === guessId) {
        correct = true
        resultEl.insertAdjacentHTML('beforeend', '<i class="fas fa-check fa-lg" style="float:right;margin:0.25rem 0"></i>')
      }
    }
  }

  if (!correct) {
    const guessEl = document.getElementById(guessId)
    if (guessEl) {
      guessEl.classList.add('incorrect-answer')
      guessEl.insertAdjacentHTML('beforeend', '<i class="fas fa-times fa-lg" style="float:right;margin:0.25rem 0"></i>')
    }
  }

  updateQuizStatistics(serverResponse)

  const nextBtn = document.getElementById('nextButton')
  if (nextBtn) {
    nextBtn.classList.remove('tj-invisible')
    nextBtn.focus()
  }
}

document.addEventListener('click', (event) => {
  const btn = event.target.closest('.multiple-choice-button')
  if (!btn) return
  if (btn.classList.contains('disabled')) return

  document.querySelectorAll('.multiple-choice-button').forEach(b => {
    b.setAttribute('disabled', 'disabled')
    b.classList.add('disabled')
  })

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  fetch(window.location.pathname, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRF-Token': csrfToken,
      'Accept': 'application/json'
    },
    body: new URLSearchParams({ 'answer[id]': btn.id.slice(9) })
  })
    .then(r => r.json())
    .then(result => processMultipleChoiceResponse(result, btn.id))
})
