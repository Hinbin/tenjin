import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  async flag(event) {
    event.preventDefault();
    const response = await csrfFetch(this.element.href, { method: "POST" });
    if (!response.ok) {
      console.error("Flag question POST failed", response.status);
      return;
    }

    const icon = this.element.querySelector("i.fa-flag");
    if (icon.classList.contains("far")) {
      icon.classList.replace("far", "fas");
      Modal.getOrCreateInstance(
        document.getElementById("feedbackModal"),
      ).show();
    } else {
      icon.classList.replace("fas", "far");
    }
  }
}
