import { Controller } from "@hotwired/stimulus"

// question_builder — authoring UI for the structured question types (drag_drop, matrix, fill_blank,
// ordering). Owns a single source of truth (this.model / this.rows), re-renders the editor on every
// change, and serialises to the hidden question[config] field so a normal form submit carries the JSON.
export default class extends Controller {
  static targets = ["config", "editor"]
  static values = { type: String }

  // drag_drop, fill_blank and ordering all edit a list of rows; matrix edits this.model directly.
  connect () {
    try {
      this.model = JSON.parse(this.configTarget.value || "{}")
    } catch {
      this.model = {}
    }
    if (this.typeValue === "drag_drop") this.normaliseDragDrop()
    if (this.typeValue === "fill_blank") this.normaliseFillBlank()
    if (this.typeValue === "ordering") this.normaliseOrdering()
    if (this.typeValue === "matrix") this.normaliseMatrix()
    this.render()
  }

  // ---- shared ----------------------------------------------------------------
  uid (prefix) { return prefix + Math.random().toString(36).slice(2, 8) }

  // Pull the live DOM state into this.model/this.rows, then write the JSON config. Bound to input/
  // change on the editor (see the partial) so every edit keeps the hidden field current for submit.
  serialize () {
    if (!this.editorTarget.firstChild) return
    if (this.typeValue === "matrix") this.captureMatrix()
    else if (this.typeValue === "ordering") this.captureOrdering()
    else this.captureDragDrop()
    this.configTarget.value = JSON.stringify(this.buildConfig())
  }

  render () {
    this.editorTarget.innerHTML = this.editorHtml()
    this.serialize()
  }

  editorHtml () {
    switch (this.typeValue) {
      case "matrix": return this.matrixHtml()
      case "fill_blank": return this.fillBlankHtml()
      case "ordering": return this.orderingHtml()
      default: return this.dragDropHtml()
    }
  }

  buildConfig () {
    switch (this.typeValue) {
      case "matrix":
        return { rows: this.model.rows, columns: this.model.columns, correct: this.model.correct }
      case "fill_blank": {
        const answer = {}
        this.rows.forEach(r => this.slotList(r.slot).forEach(slot => { answer[slot] = r.text }))
        return { answer }
      }
      case "ordering":
        return { items: this.rows.map(r => ({ id: r.id, text: r.text })), order: this.rows.map(r => r.id) }
      default: {
        // A blank can have several correct items, so each blank's answer is an array of item ids.
        const answer = {}
        this.rows.forEach(r => this.slotList(r.slot).forEach(slot => { (answer[slot] ||= []).push(r.id) }))
        return { items: this.rows.map(r => ({ id: r.id, text: r.text })), answer }
      }
    }
  }

  // ---- drag and drop ---------------------------------------------------------
  normaliseDragDrop () {
    // The cloze sentence lives in the Question Text field; here we only manage the draggable items.
    // An item can answer several blanks, so the editable "slot" field is a comma-separated list of
    // blank numbers ("" = distractor).
    const answer = this.model.answer || {}
    // A blank's answer may be a single id or an array of ids (several correct items for one blank).
    const slotsFor = (id) => Object.keys(answer).filter(slot => [].concat(answer[slot]).includes(id)).join(", ")
    this.rows = (this.model.items || []).map(item => ({ id: item.id, text: item.text, slot: slotsFor(item.id) }))
    if (this.rows.length === 0) this.rows = [this.blankItem(), this.blankItem()]
  }

  blankItem () { return { id: this.uid("i"), text: "", slot: "" } }

  // Parse a "Blank #(s)" field ("1", "1,3", "1 3") into individual blank numbers.
  slotList (value) { return String(value).split(/[\s,]+/).map(s => s.trim()).filter(Boolean) }

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

  // Pull current item field values out of the DOM into this.rows so edits survive a re-render. Shared
  // by drag_drop and fill_blank, whose rows both carry text + slot fields.
  captureDragDrop () {
    this.editorTarget.querySelectorAll(".tjs-builder__row").forEach((row, i) => {
      if (!this.rows[i]) return
      this.rows[i].text = row.querySelector("[data-field=item-text]").value
      const slot = row.querySelector("[data-field=item-slot]")
      if (slot) this.rows[i].slot = slot.value
    })
  }

  // ---- fill_blank ------------------------------------------------------------
  // One row per blank: { slot: blank number, text: accepted answer(s) }. The cloze sentence lives in
  // the Question Text field, exactly like drag_drop; here we only collect the typed answers.
  normaliseFillBlank () {
    const answer = this.model.answer || {}
    this.rows = Object.keys(answer).map(slot => ({ id: this.uid("b"), slot, text: answer[slot] }))
    if (this.rows.length === 0) this.rows = [this.blankAnswer("1"), this.blankAnswer("2")]
  }

  blankAnswer (slot = "") { return { id: this.uid("b"), slot, text: "" } }

  fillBlankHtml () {
    const items = this.rows.map((r, i) => `
      <div class="tjs-builder__row" data-index="${i}">
        <input class="tjk-input tjs-builder__slot" data-field="item-slot" value="${this.esc(r.slot)}" placeholder="Blank #">
        <input class="tjk-input" data-field="item-text" value="${this.esc(r.text)}" placeholder="Accepted answer(s) — separate alternatives with |">
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeItem" data-index="${i}">Remove</button>
      </div>`).join("")
    return `
      <label class="tjk-label">Accepted answers — write the sentence with {{1}}, {{2}}, … blanks in the Question Text box above.</label>
      <div class="tjs-builder__items">${items}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addBlank">Add blank</button>`
  }

  addBlank () { this.captureDragDrop(); this.rows.push(this.blankAnswer()); this.render() }

  // ---- ordering --------------------------------------------------------------
  // Rows ARE the correct order, top (first) to bottom (last). Students see them shuffled.
  normaliseOrdering () {
    const items = this.model.items || []
    const order = this.model.order || items.map(i => i.id)
    this.rows = order.map(id => items.find(i => i.id === id)).filter(Boolean).map(i => ({ id: i.id, text: i.text }))
    if (this.rows.length === 0) this.rows = [this.orderingItem(), this.orderingItem()]
  }

  orderingItem () { return { id: this.uid("o"), text: "" } }

  orderingHtml () {
    const items = this.rows.map((r, i) => `
      <div class="tjs-builder__row" data-index="${i}">
        <span class="tjs-builder__ordinal">${i + 1}</span>
        <input class="tjk-input" data-field="item-text" value="${this.esc(r.text)}" placeholder="Step text">
        <button type="button" class="tj-btn-secondary" data-action="question-builder#moveUp" data-index="${i}" aria-label="Move up">↑</button>
        <button type="button" class="tj-btn-secondary" data-action="question-builder#moveDown" data-index="${i}" aria-label="Move down">↓</button>
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeItem" data-index="${i}">Remove</button>
      </div>`).join("")
    return `
      <label class="tjk-label">Items in the correct order — top is first, bottom is last.</label>
      <div class="tjs-builder__items">${items}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addOrderingItem">Add item</button>`
  }

  addOrderingItem () { this.captureOrdering(); this.rows.push(this.orderingItem()); this.render() }

  moveUp (event) { this.swapRows(Number(event.currentTarget.dataset.index), -1) }
  moveDown (event) { this.swapRows(Number(event.currentTarget.dataset.index), 1) }

  swapRows (index, delta) {
    this.captureOrdering()
    const target = index + delta
    if (target < 0 || target >= this.rows.length) return
    ;[this.rows[index], this.rows[target]] = [this.rows[target], this.rows[index]]
    this.render()
  }

  captureOrdering () {
    this.editorTarget.querySelectorAll(".tjs-builder__row").forEach((row, i) => {
      if (this.rows[i]) this.rows[i].text = row.querySelector("[data-field=item-text]").value
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
