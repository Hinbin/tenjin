import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["fields"];

  add(event) {
    event.preventDefault();
    const trigger = event.currentTarget;
    const time = new Date().getTime();
    const regexp = new RegExp(trigger.dataset.id, "g");
    this.fieldsTarget.insertAdjacentHTML(
      "beforeend",
      trigger.dataset.fields.replace(regexp, time),
    );
  }

  removeRow(event) {
    event.preventDefault();
    const trigger = event.currentTarget;
    const destroyFlag = trigger.previousElementSibling;
    if (destroyFlag) destroyFlag.value = "1";
    trigger.closest("tr").remove();
  }

  removeRecord(event) {
    event.preventDefault();
    const trigger = event.currentTarget;
    const form = trigger.closest("form");
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = `${trigger.dataset.objectName}[_destroy]`;
    input.value = "true";
    form.appendChild(input);
    form.submit();
  }
}
