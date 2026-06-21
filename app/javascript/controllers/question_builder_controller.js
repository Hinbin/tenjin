import { Controller } from "@hotwired/stimulus"

// question_builder — authoring UI for the structured question types (drag_drop, matrix). Owns a
// single source of truth (this.data), re-renders the editor on every change, and serialises to the
// hidden question[config] field so a normal form submit carries the JSON config.
export default class extends Controller {
  static targets = ["config", "editor"]
  static values = { type: String }

  connect () {
    try {
      this.data = JSON.parse(this.configTarget.value || "{}")
    } catch {
      this.data = {}
    }
    if (this.typeValue === "drag_drop") this.normaliseDragDrop()
    if (this.typeValue === "matrix") this.normaliseMatrix()
    this.render()
  }

  // ---- shared ----------------------------------------------------------------
  uid (prefix) { return prefix + Math.random().toString(36).slice(2, 8) }

  // Pull the live DOM state into this.data, then write the JSON config. Bound to input/change on the
  // editor (see the partial) so every edit keeps the hidden field current for submit.
  serialize () {
    if (!this.editorTarget.firstChild) return
    if (this.typeValue === "matrix") this.captureMatrix()
    else this.captureDragDrop()
    this.configTarget.value = JSON.stringify(this.buildConfig())
  }

  render () {
    this.editorTarget.innerHTML = this.typeValue === "matrix" ? this.matrixHtml() : this.dragDropHtml()
    this.serialize()
  }

  // ---- drag and drop ---------------------------------------------------------
  normaliseDragDrop () {
    this.data.text ||= ""
    // Convert stored {items, answer} into editable rows carrying their slot number ("" = distractor).
    const answer = this.data.answer || {}
    const slotFor = (id) => Object.keys(answer).find(slot => answer[slot] === id) || ""
    this.rows = (this.data.items || []).map(item => ({ id: item.id, text: item.text, slot: slotFor(item.id) }))
    if (this.rows.length === 0) this.rows = [this.blankItem(), this.blankItem()]
  }

  blankItem () { return { id: this.uid("i"), text: "", slot: "" } }

  buildConfig () {
    if (this.typeValue === "matrix") {
      return { rows: this.data.rows, columns: this.data.columns, correct: this.data.correct }
    }
    const answer = {}
    this.rows.forEach(r => { if (String(r.slot).trim() !== "") answer[String(r.slot).trim()] = r.id })
    return { text: this.data.text, items: this.rows.map(r => ({ id: r.id, text: r.text })), answer }
  }

  dragDropHtml () {
    const items = this.rows.map((r, i) => `
      <div class="tjs-builder__row" data-index="${i}">
        <input class="tjk-input" data-field="item-text" value="${this.esc(r.text)}" placeholder="Item text">
        <input class="tjk-input tjs-builder__slot" data-field="item-slot" value="${this.esc(r.slot)}" placeholder="Blank # (blank = distractor)">
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeItem" data-index="${i}">Remove</button>
      </div>`).join("")
    return `
      <label class="tjk-label">Cloze text — mark blanks with {{1}}, {{2}}, …</label>
      <textarea class="tjk-input" data-field="text" rows="3" data-action="input->question-builder#sync">${this.esc(this.data.text)}</textarea>
      <div class="tjs-builder__items">${items}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addItem">Add item</button>`
  }

  addItem () { this.captureDragDrop(); this.rows.push(this.blankItem()); this.render() }

  removeItem (event) {
    this.captureDragDrop()
    this.rows.splice(Number(event.currentTarget.dataset.index), 1)
    this.render()
  }

  // Pull current field values out of the DOM into this.data/this.rows so edits survive a re-render.
  captureDragDrop () {
    const textEl = this.editorTarget.querySelector("[data-field=text]")
    if (textEl) this.data.text = textEl.value
    this.editorTarget.querySelectorAll(".tjs-builder__row").forEach((row, i) => {
      if (!this.rows[i]) return
      this.rows[i].text = row.querySelector("[data-field=item-text]").value
      this.rows[i].slot = row.querySelector("[data-field=item-slot]").value
    })
  }

  // ---- matrix ---------------------------------------------------------------
  normaliseMatrix () {
    this.data.rows ||= [{ id: this.uid("r"), label: "" }]
    this.data.columns ||= [{ id: this.uid("c"), label: "" }]
    this.data.correct ||= {}
  }

  captureMatrix () {
    this.editorTarget.querySelectorAll("[data-row-input]").forEach(el => {
      this.data.rows.find(r => r.id === el.dataset.rowInput).label = el.value
    })
    this.editorTarget.querySelectorAll("[data-col-input]").forEach(el => {
      this.data.columns.find(c => c.id === el.dataset.colInput).label = el.value
    })
    this.data.correct = {}
    this.editorTarget.querySelectorAll("input[type=checkbox]:checked").forEach(box => {
      (this.data.correct[box.dataset.row] ||= []).push(box.dataset.col)
    })
  }

  matrixHtml () {
    const head = this.data.columns.map(c =>
      `<th><input class="tjk-input" data-col-input="${c.id}" value="${this.esc(c.label)}" placeholder="Column">
        <button type="button" class="tj-btn-danger tj-btn--sm" data-action="question-builder#removeColumn" data-id="${c.id}">×</button></th>`).join("")
    const body = this.data.rows.map(r => {
      const cells = this.data.columns.map(c =>
        `<td><input type="checkbox" data-row="${r.id}" data-col="${c.id}" ${(this.data.correct[r.id] || []).includes(c.id) ? "checked" : ""}></td>`).join("")
      return `<tr><th><input class="tjk-input" data-row-input="${r.id}" value="${this.esc(r.label)}" placeholder="Row">
        <button type="button" class="tj-btn-danger tj-btn--sm" data-action="question-builder#removeRow" data-id="${r.id}">×</button></th>${cells}</tr>`
    }).join("")
    return `
      <table class="tjs-matrix"><thead><tr><th></th>${head}</tr></thead><tbody>${body}</tbody></table>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addRow">Add row</button>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addColumn">Add column</button>`
  }

  addRow () { this.captureMatrix(); this.data.rows.push({ id: this.uid("r"), label: "" }); this.render() }
  addColumn () { this.captureMatrix(); this.data.columns.push({ id: this.uid("c"), label: "" }); this.render() }

  removeRow (event) {
    this.captureMatrix()
    this.data.rows = this.data.rows.filter(r => r.id !== event.currentTarget.dataset.id)
    this.render()
  }

  removeColumn (event) {
    this.captureMatrix()
    this.data.columns = this.data.columns.filter(c => c.id !== event.currentTarget.dataset.id)
    this.render()
  }

  esc (value) {
    return String(value ?? "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
