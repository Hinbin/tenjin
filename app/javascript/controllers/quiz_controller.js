import { Controller } from '@hotwired/stimulus'

// quiz_controller — answer-reveal juice for the live quiz (Plan 01, Phase 2).
//
// Presentation only: the answer submission + scoring stays in questions/*_question.js. Those
// scripts dispatch a `quiz:answered` event once the server responds; this controller turns that
// into a correct/incorrect flash, a wrong-answer shake, and a combo pop.
//
// MOTION SAFETY: every visual is additive and decorative. The flash/shake/pop base states are
// invisible and the animations only run under @media (prefers-reduced-motion: no-preference)
// (see _quiz.scss). Class cleanup is on a timer, not animationend, so nothing is left stuck on
// when motion is off and no animation (or animationend) ever fires.
export default class extends Controller {
  static targets = ['flash', 'pop', 'answerFx']

  connect () {
    this.onAnswered = this.handleAnswered.bind(this)
    document.addEventListener('quiz:answered', this.onAnswered)
  }

  disconnect () {
    document.removeEventListener('quiz:answered', this.onAnswered)
  }

  handleAnswered (event) {
    const { correct, streak, multiplier } = event.detail || {}
    this.flash(correct)
    if (correct) {
      this.pop(`+${multiplier ?? 0}`, streak >= 2 ? `COMBO ×${streak}` : null, true)
      this.burst()
    } else {
      this.shake()
      this.pop('MISS', null, false)
    }
  }

  flash (good) {
    if (!this.hasFlashTarget) return
    const cls = good ? 'tjs-quiz__flash--good' : 'tjs-quiz__flash--bad'
    this.restart(this.flashTarget, cls, 500)
  }

  shake () {
    this.restart(this.element, 'tjs-quiz--shake', 520)
  }

  burst () {
    if (!this.hasAnswerFxTarget) return
    this.restart(this.answerFxTarget, 'tjs-quiz__fx--burst', 700)
  }

  pop (text, sub, good) {
    if (!this.hasPopTarget) return
    const el = this.popTarget
    el.innerHTML = ''
    if (sub) {
      const subEl = document.createElement('div')
      subEl.className = 'tjs-quiz__pop-sub'
      subEl.textContent = sub
      el.appendChild(subEl)
    }
    const textEl = document.createElement('div')
    textEl.className = `tjs-quiz__pop-text tjs-quiz__pop-text--${good ? 'good' : 'bad'}`
    textEl.textContent = text
    el.appendChild(textEl)
    this.restart(el, 'tjs-quiz__pop--show', 1000)
  }

  // Re-trigger a one-shot CSS animation: drop the class, force reflow, re-add, then clear on a timer.
  restart (el, cls, ms) {
    el.classList.remove(cls)
    void el.offsetWidth
    el.classList.add(cls)
    window.setTimeout(() => el.classList.remove(cls), ms)
  }
}
