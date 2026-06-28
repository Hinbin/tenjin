import { Controller } from "@hotwired/stimulus"

// Keeps the review queue tidy as items are approved/rejected via Turbo Streams: drops topic
// sections once their last question is gone, and shows the empty-state when the queue clears.
export default class extends Controller {
  static targets = ["section", "empty"]

  connect() {
    this.prune = this.prune.bind(this)
    document.addEventListener("turbo:before-stream-render", this.prune)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.prune)
  }

  prune() {
    // Run after Turbo has applied the stream so removed items are no longer in the DOM.
    requestAnimationFrame(() => {
      this.sectionTargets.forEach((section) => {
        if (!section.querySelector(".tj-review-item")) section.remove()
      })

      if (this.hasEmptyTarget && !this.element.querySelector(".tj-review-item")) {
        this.emptyTarget.hidden = false
      }
    })
  }
}
