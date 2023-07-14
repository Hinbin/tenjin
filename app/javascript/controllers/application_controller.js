import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="application"
export default class extends Controller {

  getCsrfToken() {
    // If the token is in the head, return it
    if (document.getElementsByName("csrf-token").length > 0) {
      return document.getElementsByName("csrf-token")[0].content
    }
    return false
  }
  
}
