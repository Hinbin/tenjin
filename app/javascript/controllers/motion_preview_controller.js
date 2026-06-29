import { Controller } from "@hotwired/stimulus"
import { runMotionFamily } from "controllers/motion_controller"

// motion_preview_controller — a live miniature of the equipped Atmosphere, shown on the Reward Shop
// catalogue tile. Reuses the exact particle builders that paint the full backdrop (motion_controller)
// so the thumbnail looks like the real effect (petals fall, code rains, stars warp…) instead of a
// generic stand-in. Clipped to the small tile by `overflow: hidden` in shop.scss. Honours the same
// motion gates: server-passed `enabled` (users.motion_pref) + OS prefers-reduced-motion.
export default class extends Controller {
  static values = { id: String, token: String, enabled: Boolean }

  connect() {
    if (!this.enabledValue) return
    runMotionFamily(this.element, this.idValue, this.tokenValue || "var(--n1)")
  }

  disconnect() {
    this.element.replaceChildren()
  }
}
