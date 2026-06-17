// students-table, users-table, employees-table now use table_controller.js.
// Password confirmation textbox logic moved here from jQuery.

document.addEventListener('turbo:load', () => {
  if (page.controller() !== 'users' && page.controller() !== 'schools') return

  const textbox = document.getElementById('confirmAllPasswordResetTextbox')
  if (!textbox) return

  textbox.addEventListener('input', () => {
    const btn = document.getElementById('confirmAllPasswordResetButton')
    const schoolName = document.getElementById('schoolName')?.textContent ?? ''
    if (!btn) return

    if (textbox.value === schoolName) {
      btn.classList.remove('disabled')
    } else {
      btn.classList.add('disabled')
    }
  })
})
