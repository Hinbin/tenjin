import { Controller } from "@hotwired/stimulus";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  static targets = ["input", "submitButton", "nextButton"];
  static outlets = ["quiz-stats"];

  async check(event) {
    event.preventDefault();
    const guess = this.inputTarget.value;
    this.submitButtonTarget.setAttribute("disabled", "disabled");
    this.inputTarget.setAttribute("disabled", "disabled");

    const response = await csrfFetch(window.location.pathname, {
      method: "PUT",
      body: JSON.stringify({ answer: { short_answer: guess } }),
    });
    if (!response.ok) {
      console.error("Quiz answer PUT failed", response.status);
      return;
    }
    const payload = await response.json();

    this._mark(payload.answer, guess);
    if (this.hasQuizStatsOutlet) this.quizStatsOutlet.update(payload);

    this.nextButtonTarget.classList.remove("invisible");
    this.nextButtonTarget.focus();
  }

  _mark(results, guess) {
    const button = this.submitButtonTarget;
    const correct = results.some(
      (r) => r.text.toUpperCase() === guess.toUpperCase(),
    );

    if (correct) {
      button.classList.add("correct-answer");
      button.textContent = "Correct!";
      button.insertAdjacentHTML(
        "beforeend",
        '<i class="fas fa-check fa-lg float-right my-1"></i>',
      );
      return;
    }
    if (results[0]) {
      button.classList.add("incorrect-answer");
      button.textContent = "Incorrect";
      button.insertAdjacentHTML(
        "beforeend",
        '<i class="fas fa-times fa-lg float-right my-1"></i>',
      );
      this.inputTarget.classList.add("correct-answer");
      this.inputTarget.value =
        results.length === 1
          ? results[0].text
          : results.map((r) => r.text).join(" or ");
    }
  }
}
