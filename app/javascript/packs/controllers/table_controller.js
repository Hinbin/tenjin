import { Controller } from '@hotwired/stimulus'

// Lightweight sortable/searchable/pageable table.
// Attach to a wrapper <div> that contains a <table>.
// Targets: search, info, prev, next  (all optional)
// Values:  pageLength (Number, 0 = show all, default 25)
//          order (Array, e.g. [[2,"desc"]], default [])
// Cells can carry data-order="<unix-ms>" for numeric date sort.
// CSV export: any button with data-action="click->table#exportCsv".
export default class extends Controller {
  static targets = ['search', 'info', 'prev', 'next']
  static values = {
    pageLength: { type: Number, default: 25 },
    order: { type: Array, default: [] }
  }

  connect () {
    this._page = 1
    this._filter = ''
    this._sortCol = -1
    this._sortDir = 'asc'

    if (this.orderValue.length) {
      this._sortCol = this.orderValue[0][0]
      this._sortDir = this.orderValue[0][1]
    }

    this._table().querySelectorAll('thead tr:first-child th').forEach((th, colIdx) => {
      th.style.cursor = 'pointer'
      th.addEventListener('click', () => this._onSort(colIdx))
    })

    this._render()
  }

  search (event) {
    this._filter = event.target.value.toLowerCase()
    this._page = 1
    this._render()
  }

  prev () {
    if (this._page > 1) { this._page--; this._render() }
  }

  next () {
    if (this._page < this._pages()) { this._page++; this._render() }
  }

  exportCsv () {
    const table = this._table()
    const ths = Array.from(table.querySelectorAll('thead th'))
    const headers = ths
      .filter(th => !th.dataset.noExport)
      .map(th => `"${th.textContent.trim().replace(/"/g, '""')}"`)

    const rows = this._sortedRows().map(tr =>
      Array.from(tr.cells)
        .filter((_, i) => !ths[i]?.dataset.noExport)
        .map(td => `"${td.textContent.trim().replace(/"/g, '""')}"`)
        .join(',')
    )

    const csv = [headers.join(','), ...rows].join('\n')
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = 'export.csv'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }

  _table () {
    return this.element.tagName === 'TABLE'
      ? this.element
      : this.element.querySelector('table')
  }

  _allRows () {
    return Array.from(this._table().tBodies[0]?.rows ?? [])
  }

  _filteredRows () {
    if (!this._filter) return this._allRows()
    return this._allRows().filter(tr => {
      const text = Array.from(tr.cells).map(td => td.textContent.trim()).join(' ').toLowerCase()
      return text.includes(this._filter)
    })
  }

  _sortedRows () {
    if (this._sortCol < 0) return this._filteredRows()
    return [...this._filteredRows()].sort((a, b) => {
      const cellA = a.cells[this._sortCol]
      const cellB = b.cells[this._sortCol]
      const va = cellA?.dataset.order ?? cellA?.textContent.trim() ?? ''
      const vb = cellB?.dataset.order ?? cellB?.textContent.trim() ?? ''
      const na = Number(va)
      const nb = Number(vb)
      const numeric = !isNaN(na) && !isNaN(nb) && va !== '' && vb !== ''
      const cmp = numeric ? na - nb : String(va).localeCompare(String(vb))
      return this._sortDir === 'asc' ? cmp : -cmp
    })
  }

  _pages () {
    if (this.pageLengthValue <= 0) return 1
    return Math.max(1, Math.ceil(this._sortedRows().length / this.pageLengthValue))
  }

  _render () {
    const rows = this._sortedRows()
    const pl = this.pageLengthValue
    const start = pl > 0 ? (this._page - 1) * pl : 0
    const end = pl > 0 ? start + pl : rows.length

    this._allRows().forEach(tr => { tr.hidden = true })
    rows.forEach((tr, i) => { tr.hidden = !(i >= start && i < end) })

    if (this.hasInfoTarget) {
      const s = rows.length ? start + 1 : 0
      const e = Math.min(end, rows.length)
      this.infoTarget.textContent = `Showing ${s}–${e} of ${rows.length}`
    }
    if (this.hasPrevTarget) this.prevTarget.disabled = this._page <= 1
    if (this.hasNextTarget) this.nextTarget.disabled = this._page >= this._pages()
  }

  _onSort (colIdx) {
    if (this._sortCol === colIdx) {
      this._sortDir = this._sortDir === 'asc' ? 'desc' : 'asc'
    } else {
      this._sortCol = colIdx
      this._sortDir = 'asc'
    }
    this._page = 1

    const ths = this._table().querySelectorAll('thead tr:first-child th')
    ths.forEach(th => th.classList.remove('sorted-asc', 'sorted-desc'))
    if (ths[colIdx]) ths[colIdx].classList.add('sorted-' + this._sortDir)

    this._render()
  }
}
