import { Controller } from "@hotwired/stimulus"

// motion_controller — the purchasable, skin-locked Atmosphere layer (Plan 01).
//
// Ported from MotionLayer in design/tenjin-design-system/project/flow/skins/sk-cosmetics.jsx.
// Attached to .tjs-motion in shared/skin/_backdrop. The server resolves the equipped motion id +
// token from Theme::Selection and whether motion is enabled (users.motion_pref) and renders them as
// data-values. We inject the particle DOM only when motion is enabled AND the OS isn't in
// reduced-motion — so nothing animates (and nothing is even created) otherwise. Keyframes live in
// app/assets/stylesheets/skins/_motion.scss; this controller only positions/animates the particles.
//
// `id` selects a particle family (petals, rain, snow, …); `token` is the palette CSS var tint.
export default class extends Controller {
  static values = { id: String, token: String, enabled: Boolean }

  connect() {
    const id = this.idValue
    if (!this.enabledValue || !id || id === "none") return
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const build = BUILDERS[id]
    if (build) build(this.element, this.tokenValue || "var(--n1)")
  }

  disconnect() {
    this.element.replaceChildren()
  }
}

const rnd = (a, b) => a + Math.random() * (b - a)

// Create a positioned element, apply inline styles + per-particle CSS vars, and append it.
function part(parent, tag, styles, vars = {}) {
  const el = document.createElement(tag)
  Object.assign(el.style, { position: "absolute", ...styles })
  for (const [k, v] of Object.entries(vars)) el.style.setProperty(k, v)
  parent.appendChild(el)
  return el
}

const times = (n) => Array.from({ length: n }, (_, i) => i)
const anim = (name, dur, ease, delay) => `${name} ${dur}s ${ease} ${delay}s infinite`

// ── per-family particle builders (counts/ranges mirror the prototype at full density) ──
const BUILDERS = {
  petals: (root, col) => fallingLeaf(root, false),
  leaves: (root, col) => fallingLeaf(root, true),
  embers: (root, col) => rising(root, col, "embers"),
  bubbles: (root, col) => rising(root, col, "bubbles"),
  hearts: (root, col) => rising(root, col, "hearts"),
  snow: (root, col) => times(16).forEach(() => {
    part(root, "i", {
      top: "-12px", left: rnd(2, 96) + "%", width: rnd(4, 8) + "px", height: rnd(4, 8) + "px",
      background: col, animation: anim("tjs-fall", rnd(6, 11), "linear", rnd(0, 9)),
    }, { "--px": rnd(-8, 8) + "px" })
  }),
  stars: (root, col) => {
    const hub = part(root, "div", { left: "50%", top: "46%", width: 0, height: 0 })
    times(20).forEach(() => {
      const a = rnd(0, Math.PI * 2), dist = rnd(60, 150)
      part(hub, "i", {
        width: "3px", height: "3px", borderRadius: "50%", background: col, boxShadow: `0 0 6px ${col}`,
        animation: anim("tjs-warpstar", rnd(1.6, 3), "ease-in", rnd(0, 2.4)),
      }, { "--tx": Math.cos(a) * dist + "px", "--ty": Math.sin(a) * dist + "px" })
    })
  },
  rain: (root, col) => times(13).forEach(() => {
    part(root, "i", {
      top: "-120px", left: rnd(2, 96) + "%", width: "2px", height: rnd(40, 110) + "px",
      background: `linear-gradient(${col}, transparent)`, boxShadow: `0 0 5px ${col}`,
      animation: anim("tjs-coderain", rnd(2.4, 4.4), "linear", rnd(0, 3)),
    })
  }),
  clouds: (root, col) => times(4).forEach(() => {
    const s = rnd(34, 70)
    const wrap = part(root, "div", {
      top: rnd(8, 64) + "%", left: "-90px", animation: anim("tjs-driftx", rnd(22, 40), "linear", rnd(0, 12)),
    })
    wrap.innerHTML = `<svg viewBox="0 0 40 20" width="${s}" height="${s * 0.5}"><g fill="${col}" opacity="0.55"><rect x="8" y="4" width="6" height="4"/><rect x="14" y="2" width="10" height="4"/><rect x="4" y="8" width="32" height="6"/><rect x="2" y="10" width="36" height="4"/></g></svg>`
  }),
  flashes: (root, col) => times(18).forEach(() => {
    const s = rnd(2, 5)
    part(root, "i", {
      left: rnd(2, 96) + "%", top: rnd(2, 46) + "%", width: s + "px", height: s + "px", borderRadius: "50%",
      background: "#fff", boxShadow: `0 0 ${s * 2.4}px ${col}`, opacity: 0,
      animation: anim("tjs-twinkle", rnd(1.4, 3), "ease-out", rnd(0, 3.2)),
    })
  }),
  ticker: (root, col) => {
    const cols = ["var(--n1)", "var(--gold)", "var(--n2)", "var(--n3)"]
    times(14).forEach((i) => {
      const s = rnd(5, 9)
      part(root, "i", {
        top: "-16px", left: rnd(2, 96) + "%", width: s + "px", height: s * 2 + "px",
        background: cols[i % 4], animation: anim("tjs-tickerfall", rnd(3.4, 6), "linear", rnd(0, 4)),
      })
    })
  },
}

// petals (sakura) + leaves share a falling glyph; leaves are flatter and tinted n2/gold.
function fallingLeaf(root, leaf) {
  const bg = leaf
    ? "radial-gradient(120% 120% at 30% 20%, color-mix(in srgb, var(--n2) 80%, transparent), color-mix(in srgb, var(--gold) 45%, transparent))"
    : "radial-gradient(120% 120% at 30% 20%, color-mix(in srgb, var(--n1) 78%, transparent), color-mix(in srgb, var(--n3) 55%, transparent))"
  const radius = leaf ? "0% 100% 0% 100% / 50% 50% 50% 50%" : "100% 6% 100% 6% / 6% 100% 6% 100%"
  times(9).forEach(() => {
    const s = rnd(8, 15)
    part(root, "span", {
      top: "-24px", left: rnd(4, 94) + "%", width: s + "px", height: s * (leaf ? 0.6 : 0.82) + "px",
      background: bg, borderRadius: radius, opacity: 0.58,
      animation: anim("tjs-m-petal", rnd(11, 16), "cubic-bezier(.45,0,.55,1)", rnd(0, 9)),
    }, { "--px": rnd(-30, 34) + "px" })
  })
}

// rising motes: embers (glow dots), bubbles (ringed), hearts (heart glyph) — all use tjs-rise.
function rising(root, col, kind) {
  const counts = { embers: 11, bubbles: 12, hearts: 9 }
  times(counts[kind]).forEach(() => {
    const s = kind === "embers" ? rnd(3, 6) : kind === "hearts" ? rnd(12, 22) : rnd(7, 18)
    const dur = kind === "embers" ? rnd(7, 12) : kind === "bubbles" ? rnd(8, 14) : rnd(9, 14)
    const common = {
      bottom: "-30px", left: rnd(kind === "embers" ? 6 : 4, kind === "embers" ? 92 : 94) + "%",
      animation: anim("tjs-rise", dur, "ease-in", rnd(0, kind === "embers" ? 7 : 8)),
    }
    const vars = { "--rx": rnd(-14, 14) + "px" }
    if (kind === "hearts") {
      const el = part(root, "span", common, vars)
      el.innerHTML = `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="${col}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="filter:drop-shadow(0 0 5px ${col})"><path d="M12 20S4 15 4 9a4 4 0 0 1 8-1 4 4 0 0 1 8 1c0 6-8 11-8 11z"/></svg>`
    } else if (kind === "bubbles") {
      part(root, "i", {
        ...common, width: s + "px", height: s + "px", borderRadius: "50%",
        border: `1.5px solid ${col}`, background: `color-mix(in srgb, ${col} 16%, transparent)`,
      }, vars)
    } else {
      part(root, "i", {
        ...common, width: s + "px", height: s + "px", borderRadius: "50%",
        background: col, boxShadow: `0 0 ${s}px ${col}`,
      }, vars)
    }
  })
}
