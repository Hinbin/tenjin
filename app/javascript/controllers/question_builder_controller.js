import { Controller } from "@hotwired/stimulus"

// question_builder — authoring UI for the structured question types (drag_drop, matrix). Owns a
// single source of truth (this.model), re-renders the editor on every change, and serialises to the
// hidden question[config] field so a normal form submit carries the JSON config.
export default class extends Controller {
  static targets = ["config", "editor"]
  static values = { type: String }

  connect () {
    try {
      this.model = JSON.parse(this.configTarget.value || "{}")
    } catch {
      this.model = {}
    }
    if (this.typeValue === "drag_drop") this.normaliseDragDrop()
    if (this.typeValue === "matrix") this.normaliseMatrix()
    this.render()
  }

  // ---- shared ----------------------------------------------------------------
  uid (prefix) { return prefix + Math.random().toString(36).slice(2, 8) }

  // Pull the live DOM state into this.model, then write the JSON config. Bound to input/change on the
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
    // The cloze sentence lives in the Question Text field; here we only manage the draggable items.
    // An item can answer several blanks, so the editable "slot" field is a comma-separated list of
    // blank numbers ("" = distractor).
    const answer = this.model.answer || {}
    const slotsFor = (id) => Object.keys(answer).filter(slot => answer[slot] === id).join(", ")
    this.rows = (this.model.items || []).map(item => ({ id: item.id, text: item.text, slot: slotsFor(item.id) }))
    if (this.rows.length === 0) this.rows = [this.blankItem(), this.blankItem()]
  }

  blankItem () { return { id: this.uid("i"), text: "", slot: "" } }

  // Parse a "Blank #(s)" field ("1", "1,3", "1 3") into individual blank numbers.
  slotList (value) { return String(value).split(/[\s,]+/).map(s => s.trim()).filter(Boolean) }

  buildConfig () {
    if (this.typeValue === "matrix") {
      return { rows: this.model.rows, columns: this.model.columns, correct: this.model.correct }
    }
    const answer = {}
    this.rows.forEach(r => this.slotList(r.slot).forEach(slot => { answer[slot] = r.id }))
    return { items: this.rows.map(r => ({ id: r.id, text: r.text })), answer }
  }

  dragDropHtml () {
    const items = this.rows.map((r, i) => `
      <div class="tjs-builder__row" data-index="${i}">
        <input class="tjk-input" data-field="item-text" value="${this.esc(r.text)}" placeholder="Item text">
        <input class="tjk-input tjs-builder__slot" data-field="item-slot" value="${this.esc(r.slot)}" placeholder="Blank #(s), e.g. 1 or 1,3">
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeItem" data-index="${i}">Remove</button>
      </div>`).join("")
    return `
      <label class="tjk-label">Draggable items — write the sentence with {{1}}, {{2}}, … blanks in the Question Text box above.</label>
      <div class="tjs-builder__items">${items}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addItem">Add item</button>`
  }

  addItem () { this.captureDragDrop(); this.rows.push(this.blankItem()); this.render() }

  removeItem (event) {
    this.captureDragDrop()
    this.rows.splice(Number(event.currentTarget.dataset.index), 1)
    this.render()
  }

  // Pull current item field values out of the DOM into this.rows so edits survive a re-render.
  captureDragDrop () {
    this.editorTarget.querySelectorAll(".tjs-builder__row").forEach((row, i) => {
      if (!this.rows[i]) return
      this.rows[i].text = row.querySelector("[data-field=item-text]").value
      this.rows[i].slot = row.querySelector("[data-field=item-slot]").value
    })
  }

  // ---- matrix ---------------------------------------------------------------
  normaliseMatrix () {
    this.model.rows ||= [{ id: this.uid("r"), label: "" }]
    this.model.columns ||= [{ id: this.uid("c"), label: "" }]
    this.model.correct ||= {}
  }

  captureMatrix () {
    this.editorTarget.querySelectorAll("[data-row-input]").forEach(el => {
      this.model.rows.find(r => r.id === el.dataset.rowInput).label = el.value
    })
    this.editorTarget.querySelectorAll("[data-col-input]").forEach(el => {
      this.model.columns.find(c => c.id === el.dataset.colInput).label = el.value
    })
    this.model.correct = {}
    this.editorTarget.querySelectorAll("input[type=checkbox]:checked").forEach(box => {
      (this.model.correct[box.dataset.row] ||= []).push(box.dataset.col)
    })
  }

  matrixHtml () {
    const head = this.model.columns.map(c =>
      `<th><input class="tjk-input" data-col-input="${c.id}" value="${this.esc(c.label)}" placeholder="Column">
        <button type="button" class="tj-btn-danger tj-btn--sm" data-action="question-builder#removeColumn" data-id="${c.id}">×</button></th>`).join("")
    const body = this.model.rows.map(r => {
      const cells = this.model.columns.map(c =>
        `<td><input type="checkbox" data-row="${r.id}" data-col="${c.id}" ${(this.model.correct[r.id] || []).includes(c.id) ? "checked" : ""}></td>`).join("")
      return `<tr><th><input class="tjk-input" data-row-input="${r.id}" value="${this.esc(r.label)}" placeholder="Row">
        <button type="button" class="tj-btn-danger tj-btn--sm" data-action="question-builder#removeRow" data-id="${r.id}">×</button></th>${cells}</tr>`
    }).join("")
    return `
      <table class="tjs-matrix"><thead><tr><th></th>${head}</tr></thead><tbody>${body}</tbody></table>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addRow">Add row</button>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addColumn">Add column</button>`
  }

  addRow () { this.captureMatrix(); this.model.rows.push({ id: this.uid("r"), label: "" }); this.render() }
  addColumn () { this.captureMatrix(); this.model.columns.push({ id: this.uid("c"), label: "" }); this.render() }

  removeRow (event) {
    this.captureMatrix()
    this.model.rows = this.model.rows.filter(r => r.id !== event.currentTarget.dataset.id)
    this.render()
  }

  removeColumn (event) {
    this.captureMatrix()
    this.model.columns = this.model.columns.filter(c => c.id !== event.currentTarget.dataset.id)
    this.render()
  }

  esc (value) {
    return String(value ?? "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
