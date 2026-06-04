import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  reload() {
    location.reload();
  }
}
