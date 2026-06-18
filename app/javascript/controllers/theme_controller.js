import { Controller } from "@hotwired/stimulus"

// theme_controller — applies and live-switches the reskinnable theme (Plan 01, Phase 0).
//
// Attached to <body> on every page. The server renders the correct theme inline (no flash); this
// controller's two jobs are:
//   1. connect(): apply a client-side override saved in localStorage (a choice the student made
//      before Phase 4 persists it server-side). Catalog-free — it replays a saved style string.
//   2. select(): live-switch on surfaces that pass a `catalog` value (styleguide / settings).
//      Looks up the resolved CSS vars for {skin, palette, mode} and applies + persists them.
//
// Catalog shape (from ThemeHelper#theme_catalog_json):
//   { arcade: { "0": { dark: { "--bg0": "#…", … }, light: {…} }, "1": {…} }, kawaii: {…} }
export default class extends Controller {
  static values = { catalog: Object }

  connect() {
    const style = localStorage.getItem("tjs:style")
    if (!style) return
    this.element.setAttribute("style", style)
    this.#applyAttr("skin")
    this.#applyAttr("palette")
    this.#applyAttr("mode")
  }

  // Wire controls with: data-action="theme#select"
  //   data-theme-skin-param / data-theme-palette-param / data-theme-mode-param (any subset)
  select(event) {
    const { skin, palette, mode } = event.params
    const next = {
      skin: skin ?? this.element.dataset.skin,
      palette: String(palette ?? this.element.dataset.palette),
      mode: mode ?? this.element.dataset.mode,
    }

    const vars = this.catalogValue?.[next.skin]?.[next.palette]?.[next.mode]
    if (!vars) return // global pages with no catalog: nothing to switch with

    const styleStr = Object.entries(vars).map(([k, v]) => `${k}:${v}`).join(";")
    this.element.setAttribute("style", styleStr)
    this.element.dataset.skin = next.skin
    this.element.dataset.palette = next.palette
    this.element.dataset.mode = next.mode

    localStorage.setItem("tjs:style", styleStr)
    localStorage.setItem("tjs:skin", next.skin)
    localStorage.setItem("tjs:palette", next.palette)
    localStorage.setItem("tjs:mode", next.mode)
  }

  // Clears the local override (revert to the server-rendered / equipped theme on next load).
  reset() {
    ["style", "skin", "palette", "mode"].forEach((k) => localStorage.removeItem(`tjs:${k}`))
  }

  #applyAttr(key) {
    const v = localStorage.getItem(`tjs:${key}`)
    if (v) this.element.dataset[key] = v
  }
}
