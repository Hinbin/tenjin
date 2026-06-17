import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['lessonSelect']

  loadLessons () {
    const topicId = document.getElementById('homework_topic_id').value
    const lessons = JSON.parse(document.querySelector('.jsVars').dataset.lessons)
    const matches = lessons.filter(l => String(l.topic_id) === String(topicId))
    const select = this.lessonSelectTarget

    select.innerHTML = '<option value=""></option>'

    if (matches.length) {
      matches.forEach(l => {
        const opt = document.createElement('option')
        opt.value = l.id
        opt.textContent = l.title
        select.appendChild(opt)
      })
      select.disabled = false
    } else {
      select.disabled = true
    }
  }
}
