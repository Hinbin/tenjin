import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

export default class extends Controller {
  connect() {
    this.instance = flatpickr(this.element, {
      enableTime: true,
      minDate: "today",
      time_24hr: true,
    });
  }

  disconnect() {
    this.instance?.destroy();
  }
}
