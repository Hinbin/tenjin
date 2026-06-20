import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['search', 'topicSelect', 'card', 'subjectSection']

  filter () {
    const query = this.searchTarget.value.toLowerCase().trim()
    const topicId = this.topicSelectTarget.value

    this.subjectSectionTargets.forEach(section => {
      let visible = 0
      section.querySelectorAll('[data-lesson-filter-target="card"]').forEach(card => {
        const titleOk = !query || card.dataset.title.toLowerCase().includes(query)
        const topicOk = !topicId || card.dataset.topicId === topicId
        card.hidden = !(titleOk && topicOk)
        if (titleOk && topicOk) visible++
      })
      section.hidden = visible === 0
    })
  }
}
