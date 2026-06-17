document.addEventListener('turbo:load', () => {
  if (page.controller() !== 'schools') return

  document.querySelectorAll('.select_input').forEach(select => {
    select.addEventListener('change', (event) => {
      const subjectMapId = event.target.id
      const subjectPicked = event.target.options[event.target.selectedIndex].text
      event.target.disabled = true

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      fetch('/subject_maps/' + subjectMapId, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': csrfToken
        },
        body: new URLSearchParams({ 'subject_map[name]': subjectPicked })
      }).then(() => { event.target.disabled = false })
    })
  })
})
