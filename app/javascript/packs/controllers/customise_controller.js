// src/controllers/customise_controller.js
import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ["customisationForm", "customisationId"]
 
  buy (event) {
    let customisationId = event.target.dataset['customisationId']
    let form = this.customisationFormTarget

    this.customisationIdTarget.value = customisationId
    form.submit()
  }
}

