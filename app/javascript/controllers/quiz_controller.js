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
    const { correct, streak, multiplier, pointsAwarded } = event.detail || {}
    this.flash(correct)
    if (correct) {
      // Show the actual leaderboard points earned (multiplier × bits), matching the HUD points tick;
      // fall back to the multiplier if the payload predates pointsAwarded.
      const gained = pointsAwarded ?? multiplier ?? 0
      this.pop(`+${gained}`, streak >= 2 ? `COMBO ×${streak}` : null, true)
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

  // Inject the equipped answer-effect burst: a shockwave ring plus a spray of the effect's signature
  // particles. Presentation only; motion-gated (skips under [data-motion="false"] / reduced-motion).
  burst () {
    if (!this.hasAnswerFxTarget) return
    const root = this.answerFxTarget
    if (document.body.dataset.motion === 'false') return
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

    const type = this.answerEffect()
    root.replaceChildren()

    const ring = document.createElement('span')
    ring.className = 'tjs-answerfx__ring'
    root.appendChild(ring)

    const cols = ['var(--n2)', 'var(--gold)', 'var(--n1)', 'var(--n3)']
    const n = type === 'confetti' ? 22 : type === 'fireworks' ? 24 : 18
    const frag = document.createDocumentFragment()

    for (let i = 0; i < n; i++) {
      const col = cols[i % 4]
      const p = document.createElement('span')
      p.className = 'tjs-answerfx__p'
      p.style.color = col
      p.style.setProperty('--delay', (Math.random() * 0.08).toFixed(3) + 's')

      if (type === 'confetti') {
        p.classList.add('tjs-answerfx__p--confetti')
        p.style.setProperty('--x', (Math.random() * 320 - 160).toFixed(0) + 'px')
        p.style.setProperty('--fall', (150 + Math.random() * 120).toFixed(0) + 'px')
        p.style.setProperty('--rot', (Math.random() * 900 - 450).toFixed(0) + 'deg')
      } else {
        const ang = (Math.PI * 2 * i) / n + (Math.random() * 0.7 - 0.35)
        const dist = 70 + Math.random() * 95
        p.style.setProperty('--tx', (Math.cos(ang) * dist).toFixed(0) + 'px')
        p.style.setProperty('--ty', (Math.sin(ang) * dist).toFixed(0) + 'px')
        p.style.setProperty('--rot', (Math.random() * 540 - 270).toFixed(0) + 'deg')
        if (type === 'pixel') p.classList.add('tjs-answerfx__p--pixel')
        else if (type === 'fireworks') p.classList.add('tjs-answerfx__p--firework')
        else p.innerHTML = GLYPH_SVG[type === 'sakura' ? 'sakura' : 'star'](col)
      }
      frag.appendChild(p)
    }

    root.appendChild(frag)
    window.clearTimeout(this._burstTimer)
    this._burstTimer = window.setTimeout(() => root.replaceChildren(), 1100)
  }

  // The equipped answer-effect id, read from the HUD's data-answer-effect (set server-side).
  answerEffect () {
    const hud = this.element.querySelector('[data-answer-effect]')
    return (hud && hud.dataset.answerEffect) || 'default'
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

// Filled glyph particles for the star / sakura answer-effect bursts. Paths mirror GlyphHelper::GLYPHS
// so the burst matches the shop catalogue; rendered filled (not outlined) for a brighter spark.
const GLYPH_SVG = {
  star: (c) => `<svg viewBox="0 0 24 24" width="17" height="17" fill="${c}"><path d="M12 3l2.5 5.5L20 9.5l-4 4 1 6-5-3-5 3 1-6-4-4 5.5-1z"/></svg>`,
  sakura: (c) => `<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 12m-1.4 0a1.4 1.4 0 1 0 2.8 0 1.4 1.4 0 1 0-2.8 0"/><path d="M12 5.5c2.4 0 3.9 2 3.1 4.4M16.8 8.6c1.4 2 .8 4.4-1.6 5.5M14.5 16.8c-1 2.2-3.7 2.8-5.4 1M7.2 13.8c-2.4-1.1-3-3.5-1.6-5.5M9 9.9C8.2 7.5 9.7 5.5 12 5.5"/></svg>`,
}
