import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu', 'toggler']

  toggle () {
    const isOpen = this.menuTarget.classList.toggle('tj-navbar__collapse--open')
    this.togglerTarget.setAttribute('aria-expanded', isOpen.toString())
  }

  toggleDropdown (event) {
    const dropdown = event.currentTarget.closest('.tj-navbar__dropdown')
    const isOpen = dropdown.classList.toggle('tj-navbar__dropdown--open')
    // Close other open dropdowns
    this.element.querySelectorAll('.tj-navbar__dropdown--open').forEach(d => {
      if (d !== dropdown) d.classList.remove('tj-navbar__dropdown--open')
    })
    event.stopPropagation()
  }

  // Close dropdowns when clicking outside the navbar
  closeDropdowns (event) {
    if (!this.element.contains(event.target)) {
      this.element.querySelectorAll('.tj-navbar__dropdown--open').forEach(d => {
        d.classList.remove('tj-navbar__dropdown--open')
      })
    }
  }

  connect () {
    this._outsideClick = this.closeDropdowns.bind(this)
    document.addEventListener('click', this._outsideClick)
  }

  disconnect () {
    document.removeEventListener('click', this._outsideClick)
  }
}
