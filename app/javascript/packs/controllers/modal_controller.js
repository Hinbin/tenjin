import { Controller } from '@hotwired/stimulus'

// Two modes:
//
// 1. Controller on the <dialog> itself (for auto-open flash modals):
//    <dialog data-controller="modal" data-auto-open="">…</dialog>
//    Buttons inside: data-action="click->modal#close"
//
// 2. Controller on a wrapper div containing both trigger and dialog:
//    <div data-controller="modal">
//      <button data-action="click->modal#open">Open</button>
//      <dialog data-modal-target="dialog">…</dialog>
//    </div>
//    Buttons inside dialog: data-action="click->modal#close"
export default class extends Controller {
  static targets = ['dialog']

  connect () {
    if (this.element.tagName === 'DIALOG' && 'autoOpen' in this.element.dataset) {
      this.element.showModal()
    }
  }

  open () {
    this._dialog().showModal()
  }

  close () {
    this._dialog().close()
  }

  _dialog () {
    return this.hasDialogTarget ? this.dialogTarget : this.element
  }
}
