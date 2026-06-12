import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  // Click any homework row to navigate to that homework.
  // The tr must have data-action="click->classroom#navigateRow" and data-url="/homeworks/:id".
  navigateRow (event) {
    if (event.target.closest('a, button, select')) return
    const url = event.currentTarget.dataset.url
    if (url) Turbo.visit(url)
  }

  // When a classroom's subject select changes, update the sync status display.
  // The actual PATCH is sent by Turbo via data-turbo-method on the select.
  subjectChanged () {
    const statusEl = document.getElementById('syncStatus')
    const btnEl = document.getElementById('syncButton')

    if (statusEl) statusEl.textContent = 'Needed'

    if (btnEl) {
      btnEl.className = btnEl.className
        .replace('tj-btn-primary', 'tj-btn-danger')
      btnEl.textContent = 'School sync required. Click here to start.'
    }
  }
}
