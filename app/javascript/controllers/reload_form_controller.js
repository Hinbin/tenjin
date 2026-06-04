import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  reload(event) {
    const form = event.target.closest("form");
    const data = new FormData(form);
    data.delete("authenticity_token");
    Turbo.visit(window.location.pathname + "?" + new URLSearchParams(data));
  }
}
