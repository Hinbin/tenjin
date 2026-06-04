import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["lessonSelect"];
  static values = { lessons: Array };

  loadLessons(event) {
    const topicId = event.target.value;
    const matching = this.lessonsValue.filter(
      (l) => String(l.topic_id) === String(topicId),
    );
    this.lessonSelectTarget.innerHTML = '<option value=""></option>';
    matching.forEach((l) => {
      const opt = document.createElement("option");
      opt.value = l.id;
      opt.textContent = l.title;
      this.lessonSelectTarget.appendChild(opt);
    });
    this.lessonSelectTarget.disabled = matching.length === 0;
  }
}
