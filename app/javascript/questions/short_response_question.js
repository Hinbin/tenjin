import updateQuizStatistics from './questions_shared'

function processShortResponse (serverResponse, guess) {
  const results = serverResponse.answer
  let correct = false
  const btn = document.getElementById('shortAnswerButton')
  const input = document.getElementById('shortAnswerText')

  for (const result of results) {
    if (result.text.toUpperCase() === guess.toUpperCase()) {
      if (btn) {
        btn.classList.add('correct-answer')
        btn.textContent = 'Correct!'
        btn.insertAdjacentHTML('beforeend', '<i class="fas fa-check fa-lg" style="float:right;margin:0.25rem 0"></i>')
      }
      correct = true
    }
  }

  if (!correct && results[0]) {
    if (btn) {
      btn.classList.add('incorrect-answer')
      btn.textContent = 'Incorrect'
      btn.insertAdjacentHTML('beforeend', '<i class="fas fa-times fa-lg" style="float:right;margin:0.25rem 0"></i>')
    }
    if (input) {
      input.classList.add('correct-answer')
      input.value = results.length === 1
        ? results[0].text
        : results.map(r => r.text).join(' or ')
    }
  }

  updateQuizStatistics(serverResponse)

  const nextBtn = document.getElementById('nextButton')
  if (nextBtn) {
    nextBtn.classList.remove('tj-invisible')
    nextBtn.focus()
  }
}

document.addEventListener('keypress', (e) => {
  if (e.keyCode !== 13) return
  const input = document.getElementById('shortAnswerText')
  if (e.target !== input) return
  document.getElementById('shortAnswerButton')?.click()
})

document.addEventListener('click', (event) => {
  const btn = event.target.closest('#shortAnswerButton')
  if (!btn) return
  if (btn.hasAttribute('disabled')) return

  const input = document.getElementById('shortAnswerText')
  btn.setAttribute('disabled', 'disabled')
  if (input) input.setAttribute('disabled', 'disabled')

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  fetch(window.location.pathname, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRF-Token': csrfToken,
      'Accept': 'application/json'
    },
    body: new URLSearchParams({ 'answer[short_answer]': input?.value ?? '' })
  })
    .then(r => r.json())
    .then(result => processShortResponse(result, input?.value ?? ''))
})
