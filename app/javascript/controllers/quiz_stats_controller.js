import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["streak", "multiplier", "answeredCorrect"];

  update({ streak, multiplier, answeredCorrect }) {
    this.streakTarget.textContent = streak;
    this.multiplierTarget.textContent = multiplier;
    this.answeredCorrectTarget.textContent = answeredCorrect;
  }
}
