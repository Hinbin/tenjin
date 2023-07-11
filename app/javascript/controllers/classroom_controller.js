import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="classroom"
export default class extends Controller {
  static targets = ["subject"];
  static values = { url: String };

  updateSubject() {
    const subjectID = this.subjectTarget.value;
    const url = this.urlValue;
    const token = document.getElementsByName("csrf-token")[0].content;

    let formData = new FormData();
    formData.append("subject[id]", subjectID);

    fetch(url, {
      method: "PATCH",
      headers: { "X-CSRF-Token": token },
      body: formData,
    });
  }
}
