import { Controller } from '@hotwired/stimulus'

// Dismissible alert banner. Add data-controller="alert" to the container.
// Button: data-action="click->alert#dismiss"
export default class extends Controller {
  dismiss () {
    this.element.remove()
  }
}
