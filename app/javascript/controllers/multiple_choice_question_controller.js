import { Controller } from "@hotwired/stimulus";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  static targets = ["button", "nextButton"];
  static outlets = ["quiz-stats"];

  async select(event) {
    const button = event.currentTarget;
    if (button.classList.contains("disabled")) return;

    this.buttonTargets.forEach((b) => {
      b.setAttribute("disabled", "disabled");
      b.classList.add("disabled");
    });

    const response = await csrfFetch(window.location.pathname, {
      method: "PUT",
      body: JSON.stringify({
        answer: { id: button.id.slice("response-".length) },
      }),
    });
    if (!response.ok) {
      console.error("Quiz answer PUT failed", response.status);
      return;
    }
    const payload = await response.json();

    this._mark(payload.answer, button);
    if (this.hasQuizStatsOutlet) this.quizStatsOutlet.update(payload);

    this.nextButtonTarget.classList.remove("invisible");
    this.nextButtonTarget.focus();
  }

  _mark(correctAnswers, guess) {
    let correct = false;
    for (const result of correctAnswers) {
      const el = document.getElementById(`response-${result.id}`);
      if (!el) continue;
      el.classList.add("correct-answer");
      if (el === guess) {
        correct = true;
        el.insertAdjacentHTML(
          "beforeend",
          '<i class="fas fa-check fa-lg float-right my-1 ms-2"></i>',
        );
      }
    }
    if (!correct) {
      guess.classList.add("incorrect-answer");
      guess.insertAdjacentHTML(
        "beforeend",
        '<i class="fas fa-times fa-lg float-right my-1 ms-2"></i>',
      );
    }
  }
}
