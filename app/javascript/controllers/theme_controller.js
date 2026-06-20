import { Controller } from "@hotwired/stimulus"

// theme_controller — live-switches the reskinnable theme for in-page preview (Plan 01).
//
// Attached to <body> on every page. The server renders the correct theme inline from the user's
// equipped cosmetics (Theme::Selection) — that is the single source of truth, so this controller
// does NOT persist or replay anything across loads. Its only job is live preview on surfaces that
// pass a `catalog` value (the dev styleguide): select() swaps the inline CSS vars in place, and
// reset() restores the server-rendered theme captured at connect().
//
// Catalog shape (from ThemeHelper#theme_catalog_json):
//   { arcade: { "0": { dark: { "--bg0": "#…", … }, light: {…} }, "1": {…} }, kawaii: {…} }
export default class extends Controller {
  static values = { catalog: Object }

  connect() {
    // Snapshot the server-rendered (equipped) theme so reset() can restore it.
    this.serverStyle = this.element.getAttribute("style") || ""
    this.serverSkin = this.element.dataset.skin
    this.serverPalette = this.element.dataset.palette
    this.serverMode = this.element.dataset.mode
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
  }

  // Revert the live preview back to the server-rendered / equipped theme.
  reset() {
    this.element.setAttribute("style", this.serverStyle)
    this.element.dataset.skin = this.serverSkin
    this.element.dataset.palette = this.serverPalette
    this.element.dataset.mode = this.serverMode
  }
}
