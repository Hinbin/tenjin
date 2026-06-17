import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['body']

  toggle (event) {
    event.preventDefault()
    this.bodyTarget.classList.toggle('tj-hidden')
  }
}
