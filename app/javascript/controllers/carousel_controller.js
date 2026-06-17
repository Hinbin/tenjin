import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['track', 'indicators']

  connect () {
    this.index = 0
    this.total = this.trackTarget.children.length
    this._updateIndicators()
  }

  prev () {
    this.index = (this.index - 1 + this.total) % this.total
    this._render()
  }

  next () {
    this.index = (this.index + 1) % this.total
    this._render()
  }

  goTo (event) {
    this.index = event.params.index
    this._render()
  }

  _render () {
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`
    this._updateIndicators()
  }

  _updateIndicators () {
    if (!this.hasIndicatorsTarget) return
    this.indicatorsTarget.querySelectorAll('.tj-carousel__dot').forEach((dot, i) => {
      dot.classList.toggle('tj-carousel__dot--active', i === this.index)
    })
  }
}
