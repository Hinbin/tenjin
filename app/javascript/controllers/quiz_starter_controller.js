import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  static values = { subject: String, topic: String, lesson: String };

  async start() {
    const row = this.element;
    if (row.hasAttribute("disabled")) return;
    row.setAttribute("disabled", "disabled");
    const body = {
      quiz: { subject: this.subjectValue, topic_id: this.topicValue },
    };
    if (this.hasLessonValue && this.lessonValue)
      body.quiz.lesson_id = this.lessonValue;
    const response = await csrfFetch("/quizzes", {
      method: "POST",
      body: JSON.stringify(body),
      headers: { Accept: "text/html" },
    });
    if (!response.ok) {
      console.error("Quiz create failed", response.status);
      row.removeAttribute("disabled");
      return;
    }
    Turbo.visit("/quizzes");
  }
}
