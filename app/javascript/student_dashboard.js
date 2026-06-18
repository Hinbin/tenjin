document.addEventListener('turbo:load', () => {
  document.querySelectorAll('.challenge-row, .homework-row, .topic-row').forEach(row => {
    row.addEventListener('click', (event) => {
      const tr = event.currentTarget
      const pickedSubject = tr.dataset.subject
      const pickedTopic = tr.dataset.topic
      const pickedLesson = tr.dataset.lesson
      event.currentTarget.disabled = true

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const params = new URLSearchParams({
        'quiz[subject]': pickedSubject,
        'quiz[topic_id]': pickedTopic
      })
      if (pickedLesson) params.append('quiz[lesson_id]', pickedLesson)
      fetch('/quizzes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': csrfToken
        },
        body: params
      }).then(() => Turbo.visit('/quizzes'))
    })
  })
})
