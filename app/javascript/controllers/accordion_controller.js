import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['body']

  toggle (event) {
    event.preventDefault()
    const hidden = this.bodyTarget.classList.toggle('tj-hidden')
    // Keep an aria-expanded trigger (if present) in sync; triggers without it are unaffected.
    const trigger = event.currentTarget
    if (trigger && trigger.hasAttribute('aria-expanded')) {
      trigger.setAttribute('aria-expanded', (!hidden).toString())
    }
  }
}
