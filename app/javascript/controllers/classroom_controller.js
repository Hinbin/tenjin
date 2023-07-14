import ApplicationController from "./application_controller";

// Connects to data-controller="classroom"
export default class extends ApplicationController {
  static targets = ['subject']
  static values = { url: String }

  updateSubject() {
    const subjectID = this.subjectTarget.value
    const url = this.urlValue

    let formData = new FormData()
    formData.append('subject[id]', subjectID)

    fetch(url, {
      method: 'PATCH',
      headers: { 'X-CSRF-Token': super.getCsrfToken() },
      body: formData,
    })
  }
}
