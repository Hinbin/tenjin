import { Controller } from "@hotwired/stimulus";
import { TabulatorFull as Tabulator } from "tabulator-tables";

// Custom sorter for UK datetime strings like "DD/MM/YY HH:MM".
// Tabulator defaults to a string sort which compares char-by-char and
// breaks across year boundaries.
const ukDateTimeSorter = (a, b) => {
  const parse = (s) => {
    const m = /^(\d{2})\/(\d{2})\/(\d{2}) (\d{2}):(\d{2})$/.exec(s || "");
    if (!m) return 0;
    const [, d, mo, y, h, mi] = m;
    return Date.UTC(
      2000 + parseInt(y, 10),
      parseInt(mo, 10) - 1,
      parseInt(d, 10),
      parseInt(h, 10),
      parseInt(mi, 10),
    );
  };
  return parse(a) - parse(b);
};

const namedSorters = { ukDateTime: ukDateTimeSorter };

// Field name Tabulator will use to store each row's original source-DOM
// position. Tabulator's HTML importer assigns `item[options.index] = i`
// for rows that don't already carry a value for the configured index
// field, which gives us a per-row source index that survives sort/filter.
const SRC_INDEX_FIELD = "__tabulatorSrcIdx__";

// Tabulator stores cell.innerHTML as the data value; strip tags for export.
const stripHtml = (value) => {
  if (typeof value !== "string") return value;
  const tmp = document.createElement("div");
  tmp.innerHTML = value;
  return (tmp.textContent || "").trim();
};

// Named "datatable" (rather than "tabulator") so existing
// `data-controller="datatable"` markup keeps working.
export default class extends Controller {
  static targets = ["table", "search"];
  static values = { options: { type: Object, default: {} } };

  connect() {
    // Snapshot source <tr> id/class/data-* before Tabulator regenerates rows.
    this.sourceRowAttrs = Array.from(
      this.tableTarget.querySelectorAll("tbody tr"),
    ).map((tr) => ({
      id: tr.id || null,
      className: tr.className || null,
      dataset: { ...tr.dataset },
    }));

    const opts = { ...this.optionsValue };
    if (Array.isArray(opts.columns)) {
      opts.columns = opts.columns.map((col) =>
        typeof col.sorter === "string" && namedSorters[col.sorter]
          ? { ...col, sorter: namedSorters[col.sorter] }
          : col,
      );
    }

    this.tabulator = new Tabulator(this.tableTarget, {
      layout: "fitColumns",
      autoColumns: true,
      pagination: true,
      paginationSize: 10,
      // Tabulator's clipboard module is opt-in; without this `copyToClipboard()` is a no-op.
      clipboard: true,
      columnDefaults: {
        formatter: "html",
        accessorClipboard: stripHtml,
        accessorDownload: stripHtml,
      },
      index: SRC_INDEX_FIELD,
      ...opts,
      rowFormatter: (row) => this.reapplyRowAttrs(row),
    });

    // autoColumns may surface a visible column for the synthetic index
    // field. Hide it once the table is built (only present on autoColumns
    // tables; check the columns list first to avoid a noisy "Find Error"
    // warning when explicit `columns` was supplied).
    this.tabulator.on("tableBuilt", () => {
      const hasIdxColumn = this.tabulator
        .getColumns()
        .some((c) => c.getField() === SRC_INDEX_FIELD);
      if (hasIdxColumn) {
        this.tabulator.getColumn(SRC_INDEX_FIELD).hide();
      }
    });
  }

  disconnect() {
    if (this.tabulator) this.tabulator.destroy();
  }

  filter(event) {
    const value = event.target.value;
    clearTimeout(this._filterTimeout);
    this._filterTimeout = setTimeout(() => {
      if (value) {
        this.tabulator.setFilter((row) =>
          Object.values(row).some(
            (cell) =>
              typeof cell === "string" &&
              cell.toLowerCase().includes(value.toLowerCase()),
          ),
        );
      } else {
        this.tabulator.clearFilter();
      }
    }, 150);
  }

  copy() {
    this.tabulator.copyToClipboard("active");
  }

  downloadCsv() {
    this.tabulator.download("csv", "data.csv");
  }

  reapplyRowAttrs(row) {
    const idx = row.getData()[SRC_INDEX_FIELD];
    if (idx == null) return;
    const src = this.sourceRowAttrs[idx];
    if (!src) return;
    const el = row.getElement();
    if (src.id) el.id = src.id;
    if (src.className) {
      src.className
        .split(/\s+/)
        .filter(Boolean)
        .forEach((c) => el.classList.add(c));
    }
    Object.entries(src.dataset).forEach(([k, v]) => {
      el.dataset[k] = v;
    });
  }
}
