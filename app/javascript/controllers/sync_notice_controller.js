import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status", "button"];

  notify() {
    this.statusTarget.textContent = "Needed";
    if (!this.hasButtonTarget) return; // sync-status helper renders text instead of a button mid-sync
    this.buttonTarget.classList.remove("btn-primary");
    this.buttonTarget.classList.add("btn-danger");
    this.buttonTarget.textContent =
      "School sync required. Click here to start.";
  }
}
