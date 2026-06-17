// questionTable now uses table_controller.js (no DataTables).

// add/remove answer rows: use document-level delegation so clicks work
// even during a Turbo navigation (the form element changes mid-flight).
document.addEventListener('click', (event) => {
  if (page.controller() !== 'questions') return

  const removeBtn = event.target.closest('.remove_record')
  if (removeBtn) {
    event.preventDefault()
    const prev = removeBtn.previousElementSibling
    if (prev && prev.matches('input[type=hidden]')) prev.value = '1'
    removeBtn.closest('tr')?.remove()
  }

  const addBtn = event.target.closest('.add_fields')
  if (addBtn) {
    event.preventDefault()
    const time = new Date().getTime()
    const regexp = new RegExp(addBtn.dataset.id, 'g')
    document.querySelector('.fields')?.insertAdjacentHTML('beforeend', addBtn.dataset.fields.replace(regexp, time))
  }
})

document.addEventListener('turbo:load', () => {
  if (page.controller() !== 'questions') return

  document.querySelectorAll('.save-question-text').forEach(el => {
    el.addEventListener('trix-blur', () => saveQuestionText(() => {}))
  })

  document.querySelectorAll('.check-and-save').forEach(el => {
    el.addEventListener('click', (event) => {
      const { redirect, update } = event.currentTarget.dataset
      validateAndSave(() => { Turbo.visit(redirect) }, update)
    })
  })

  document.querySelectorAll('.reload-page').forEach(el => {
    el.addEventListener('change', () => {
      const currentPath = window.location.href.split('?')[0]
      document.querySelectorAll('input[name=authenticity_token]').forEach(i => i.remove())
      const form = document.getElementById('questionForm')
      const formParams = new URLSearchParams(new FormData(form)).toString()
      Turbo.visit(currentPath + '?' + formParams)
    })
  })
})

function validateAndSave (successCallback, updatePath) {
  const correctAnswers = document.querySelectorAll('input[checked=checked]')
  const questionType = document.getElementById('questionTypeSelect')?.value

  if (correctAnswers.length === 0 && questionType !== 'short_answer') {
    document.getElementById('noCorrectAnswerModal')?.showModal()
  } else {
    saveQuestionText(successCallback, updatePath)
  }
}

function saveQuestionText (successCallback, updatePath) {
  const questionText = document.getElementById('question_question_text')?.value ?? ''
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

  fetch(updatePath, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRF-Token': csrfToken
    },
    body: new URLSearchParams({ 'question[question_text]': questionText })
  })
  // Preserve original behaviour: callback fires immediately (not on success)
  successCallback()
}
