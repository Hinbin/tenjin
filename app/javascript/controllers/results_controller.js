import { Controller } from '@hotwired/stimulus'

// Animates progress bars on quiz completion and triggers level-up celebrations.
// Level-up sequence: fill bar to 100% → snap to 0 → fill to new level pct + shake + burst.
export default class extends Controller {
  static targets = ['levelFill', 'levelStat', 'runFill']
  static values  = { levelPct: Number, leveledUp: Boolean, runPct: Number }

  connect () {
    // Two rAF calls guarantee the initial 0% width is painted before transitions activate
    requestAnimationFrame(() => requestAnimationFrame(() => this.animate()))
  }

  disconnect () {
    document.querySelectorAll('.tjs-results__particle').forEach(p => p.remove())
  }

  animate () {
    if (this.hasRunFillTarget) this.fillBar(this.runFillTarget, this.runPctValue, 80)

    if (this.leveledUpValue) {
      this.animateLevelUp()
    } else if (this.hasLevelFillTarget) {
      this.fillBar(this.levelFillTarget, this.levelPctValue, 160)
    }
  }

  fillBar (el, pct, delay) {
    el.style.width = '0%'
    setTimeout(() => { el.style.width = `${pct}%` }, delay)
  }

  animateLevelUp () {
    const fill = this.levelFillTarget
    fill.style.transition = 'width 0.75s cubic-bezier(.2,.8,.2,1)'
    fill.style.width = '0%'

    // Phase 1: fill bar to 100%, showing the level being completed
    setTimeout(() => { fill.style.width = '100%' }, 160)

    // Phase 2: snap to empty, fill new level, and celebrate
    setTimeout(() => {
      fill.style.transition = 'none'
      fill.style.width = '0%'
      void fill.offsetWidth

      fill.style.transition = 'width 0.9s cubic-bezier(.15,.85,.2,1)'
      requestAnimationFrame(() => { fill.style.width = `${this.levelPctValue}%` })

      if (this.motionAllowed) this.celebrate()
    }, 1100)
  }

  celebrate () {
    this.restart(this.element, 'tjs-results--shake', 600)

    if (this.hasLevelStatTarget) {
      setTimeout(() => {
        this.restart(this.levelStatTarget, 'tjs-results__stat-value--levelup', 900)
        this.burst(this.levelStatTarget)
      }, 80)
    }
  }

  burst (origin) {
    const rect  = origin.getBoundingClientRect()
    const cx    = rect.left + rect.width  / 2
    const cy    = rect.top  + rect.height / 2
    const skin  = document.body.dataset.skin || 'arcade'
    const specs = this.particleSpecs(skin)
    const count = 26

    for (let i = 0; i < count; i++) {
      const angle = (i / count) * 360 + (Math.random() - 0.5) * (360 / count)
      const dist  = 48 + Math.random() * 88
      const p     = document.createElement('span')

      p.className   = 'tjs-results__particle'
      p.setAttribute('aria-hidden', 'true')
      p.textContent = specs.chars[i % specs.chars.length]
      p.style.left  = `${cx}px`
      p.style.top   = `${cy}px`
      p.style.color = specs.colors[i % specs.colors.length]
      p.style.fontSize = `${9 + Math.random() * 9}px`
      p.style.setProperty('--tx', `${Math.cos(angle * Math.PI / 180) * dist}px`)
      p.style.setProperty('--ty', `${Math.sin(angle * Math.PI / 180) * dist}px`)
      p.style.animationDelay    = `${Math.random() * 0.12}s`
      p.style.animationDuration = `${0.55 + Math.random() * 0.4}s`

      document.body.appendChild(p)
      p.addEventListener('animationend', () => p.remove(), { once: true })
    }
  }

  particleSpecs (skin) {
    return ({
      arcade:  { chars: ['0', '1', '+', '✦', '#'],   colors: ['#39ff14', '#00e5ff', '#ffffff', '#ffe066'] },
      zen:     { chars: ['✿', '·', '∘', '◦', '✦'],   colors: ['#f9b8ce', '#c8e6c9', '#ffffff', '#fce4ec'] },
      famicom: { chars: ['■', '▲', '●', '★', '♦'],   colors: ['#e8153a', '#1560b4', '#f9e11b', '#ffffff'] },
      kawaii:  { chars: ['★', '♥', '✦', '·', '◆'],   colors: ['#ff6eb4', '#ffe066', '#b4f0ff', '#ffffff'] },
      manga:   { chars: ['★', '！', '☆', '✦', '◆'],  colors: ['#ffffff', '#222222', 'var(--n1)', 'var(--n3)'] },
      street:  { chars: ['◆', '●', '▲', '✦', '★'],   colors: ['var(--n1)', 'var(--n2)', 'var(--n3)', '#ffffff'] },
      pitch:   { chars: ['◉', '✦', '●', '○', '★'],   colors: ['#ffffff', 'var(--n2)', 'var(--n1)', '#c8e6c9'] },
    })[skin] || { chars: ['✦', '★', '◆', '·'], colors: ['var(--n1)', 'var(--n2)', '#ffffff'] }
  }

  get motionAllowed () {
    return document.body.dataset.motion !== 'false' &&
           window.matchMedia('(prefers-reduced-motion: no-preference)').matches
  }

  restart (el, cls, ms) {
    el.classList.remove(cls)
    void el.offsetWidth
    el.classList.add(cls)
    window.setTimeout(() => el.classList.remove(cls), ms)
  }
}
