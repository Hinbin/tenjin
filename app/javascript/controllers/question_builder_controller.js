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
    if (this.typeValue === "classify") this.normaliseClassify()
    if (this.typeValue === "match") this.normaliseMatch()
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
    else if (this.typeValue === "classify") this.captureClassify()
    else if (this.typeValue === "match") this.captureMatch()
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
      case "classify": return this.classifyHtml()
      case "match": return this.matchHtml()
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
      case "classify": {
        const correct = {}
        this.model.items.forEach(item => { if (item.target) correct[item.id] = item.target })
        return { items: this.model.items.map(i => ({ id: i.id, text: i.text })),
                 targets: this.model.targets.map(t => ({ id: t.id, label: t.label })),
                 correct }
      }
      case "match": {
        const correct = {}
        this.model.left.forEach(item => { if (item.answer) correct[item.id] = item.answer })
        return { left: this.model.left.map(l => ({ id: l.id, text: l.text })),
                 right: this.model.right.map(r => ({ id: r.id, text: r.text })),
                 correct }
      }
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

  // ---- classify ---------------------------------------------------------------
  // this.model = { items: [{ id, text, target }], targets: [{ id, label }] }
  // target on each item is the id of the correct bucket (empty string = unassigned).
  normaliseClassify () {
    const items = this.model.items || []
    const targets = this.model.targets || []
    const correct = this.model.correct || {}
    this.model.items = items.length
      ? items.map(i => ({ id: i.id, text: i.text, target: correct[i.id] || '' }))
      : [this.blankClassifyItem(), this.blankClassifyItem()]
    this.model.targets = targets.length
      ? targets.map(t => ({ id: t.id, label: t.label }))
      : [this.blankTarget(), this.blankTarget()]
  }

  blankClassifyItem () { return { id: this.uid('ci'), text: '', target: '' } }
  blankTarget () { return { id: this.uid('ct'), label: '' } }

  captureClassify () {
    this.editorTarget.querySelectorAll('[data-classify-item]').forEach(row => {
      const item = this.model.items.find(i => i.id === row.dataset.classifyItem)
      if (!item) return
      item.text   = row.querySelector('[data-field=item-text]').value
      item.target = row.querySelector('[data-field=item-target]').value
    })
    this.editorTarget.querySelectorAll('[data-classify-target]').forEach(row => {
      const target = this.model.targets.find(t => t.id === row.dataset.classifyTarget)
      if (!target) return
      target.label = row.querySelector('[data-field=target-label]').value
    })
  }

  classifyHtml () {
    const targetOptions = this.model.targets.map(t =>
      `<option value="${this.esc(t.id)}">${this.esc(t.label || '(unnamed)')}</option>`).join('')

    const itemRows = this.model.items.map(item => `
      <div class="tjs-builder__row" data-classify-item="${this.esc(item.id)}">
        <input class="tjk-input" data-field="item-text" value="${this.esc(item.text)}" placeholder="Item text">
        <select class="tjk-input" data-field="item-target">
          <option value="">— assign to target —</option>
          ${this.model.targets.map(t =>
            `<option value="${this.esc(t.id)}" ${item.target === t.id ? 'selected' : ''}>${this.esc(t.label || '(unnamed)')}</option>`
          ).join('')}
        </select>
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeClassifyItem" data-id="${this.esc(item.id)}">Remove</button>
      </div>`).join('')

    const targetRows = this.model.targets.map(target => `
      <div class="tjs-builder__row" data-classify-target="${this.esc(target.id)}">
        <input class="tjk-input" data-field="target-label" value="${this.esc(target.label)}" placeholder="Bucket label">
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeClassifyTarget" data-id="${this.esc(target.id)}">Remove</button>
      </div>`).join('')

    return `
      <label class="tjk-label">Targets (buckets)</label>
      <div class="tjs-builder__items">${targetRows}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addClassifyTarget">Add target</button>
      <label class="tjk-label" style="margin-top:1rem">Items — assign each to the correct target</label>
      <div class="tjs-builder__items">${itemRows}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addClassifyItem">Add item</button>`
  }

  addClassifyItem () {
    this.captureClassify()
    this.model.items.push(this.blankClassifyItem())
    this.render()
  }

  removeClassifyItem (event) {
    this.captureClassify()
    this.model.items = this.model.items.filter(i => i.id !== event.currentTarget.dataset.id)
    this.render()
  }

  addClassifyTarget () {
    this.captureClassify()
    this.model.targets.push(this.blankTarget())
    this.render()
  }

  removeClassifyTarget (event) {
    this.captureClassify()
    const id = event.currentTarget.dataset.id
    this.model.targets = this.model.targets.filter(t => t.id !== id)
    // Clear any item assignments that pointed to this target.
    this.model.items.forEach(i => { if (i.target === id) i.target = '' })
    this.render()
  }

  // ---- match -------------------------------------------------------------------
  // this.model = { left: [{ id, text, answer }], right: [{ id, text }] }
  // answer on each left item is the id of its correct right definition ('' = unassigned). Extra right
  // definitions with no keyword pointing at them are distractors.
  normaliseMatch () {
    const left = this.model.left || []
    const right = this.model.right || []
    const correct = this.model.correct || {}
    this.model.left = left.length
      ? left.map(l => ({ id: l.id, text: l.text, answer: correct[l.id] || '' }))
      : [this.blankMatchLeft(), this.blankMatchLeft()]
    this.model.right = right.length
      ? right.map(r => ({ id: r.id, text: r.text }))
      : [this.blankMatchRight(), this.blankMatchRight(), this.blankMatchRight()]
  }

  blankMatchLeft () { return { id: this.uid('ml'), text: '', answer: '' } }
  blankMatchRight () { return { id: this.uid('mr'), text: '' } }

  captureMatch () {
    this.editorTarget.querySelectorAll('[data-match-left]').forEach(row => {
      const item = this.model.left.find(l => l.id === row.dataset.matchLeft)
      if (!item) return
      item.text   = row.querySelector('[data-field=left-text]').value
      item.answer = row.querySelector('[data-field=left-answer]').value
    })
    this.editorTarget.querySelectorAll('[data-match-right]').forEach(row => {
      const item = this.model.right.find(r => r.id === row.dataset.matchRight)
      if (!item) return
      item.text = row.querySelector('[data-field=right-text]').value
    })
  }

  matchHtml () {
    const rightRows = this.model.right.map(r => `
      <div class="tjs-builder__row" data-match-right="${this.esc(r.id)}">
        <input class="tjk-input" data-field="right-text" value="${this.esc(r.text)}" placeholder="Definition text">
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeMatchRight" data-id="${this.esc(r.id)}">Remove</button>
      </div>`).join('')

    const leftRows = this.model.left.map(l => `
      <div class="tjs-builder__row" data-match-left="${this.esc(l.id)}">
        <input class="tjk-input" data-field="left-text" value="${this.esc(l.text)}" placeholder="Keyword">
        <select class="tjk-input" data-field="left-answer">
          <option value="">— correct definition —</option>
          ${this.model.right.map(r =>
            `<option value="${this.esc(r.id)}" ${l.answer === r.id ? 'selected' : ''}>${this.esc(r.text || '(empty)')}</option>`
          ).join('')}
        </select>
        <button type="button" class="tj-btn-danger" data-action="question-builder#removeMatchLeft" data-id="${this.esc(l.id)}">Remove</button>
      </div>`).join('')

    return `
      <label class="tjk-label">Definitions (right) — add extra ones as distractors</label>
      <div class="tjs-builder__items">${rightRows}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addMatchRight">Add definition</button>
      <label class="tjk-label" style="margin-top:1rem">Keywords (left) — pick each one's correct definition</label>
      <div class="tjs-builder__items">${leftRows}</div>
      <button type="button" class="tj-btn-primary" data-action="question-builder#addMatchLeft">Add keyword</button>`
  }

  addMatchLeft () {
    this.captureMatch()
    this.model.left.push(this.blankMatchLeft())
    this.render()
  }

  removeMatchLeft (event) {
    this.captureMatch()
    this.model.left = this.model.left.filter(l => l.id !== event.currentTarget.dataset.id)
    this.render()
  }

  addMatchRight () {
    this.captureMatch()
    this.model.right.push(this.blankMatchRight())
    this.render()
  }

  removeMatchRight (event) {
    this.captureMatch()
    const id = event.currentTarget.dataset.id
    this.model.right = this.model.right.filter(r => r.id !== id)
    // Clear any keyword whose correct definition was this one.
    this.model.left.forEach(l => { if (l.answer === id) l.answer = '' })
    this.render()
  }

  esc (value) {
    return String(value ?? "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
