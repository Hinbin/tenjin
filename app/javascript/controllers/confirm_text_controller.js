import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "button", "match"];

  check() {
    const expected = this.matchTarget.textContent.trim();
    this.buttonTarget.classList.toggle(
      "disabled",
      this.inputTarget.value !== expected,
    );
  }
}
