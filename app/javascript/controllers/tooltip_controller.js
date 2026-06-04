import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";

export default class extends Controller {
  connect() {
    this.tooltips = Array.from(
      this.element.querySelectorAll('[data-bs-toggle="tooltip"]'),
    ).map((el) => new Tooltip(el));
  }

  disconnect() {
    this.tooltips?.forEach((t) => t.dispose());
    this.tooltips = null;
  }
}
