$(document).on('turbolinks:load', () => {
  if (page.controller() === 'dashboard' && !document.getElementById('oAuthEmail')) {

    var tour = new Tour({
      steps: [
        {
          element: 'myClassrooms',
          title: 'Link your account to Google',
          content: 'Lets attach your account to your Google Login, so you do not have to remember another username and password!  Click on your name.'
        }]
    })

    tour.init()
    tour.start()
  }

  $('.challenge-row, .homework-row').off('click')

  $('.challenge-row, .homework-row').click(function (event) {
    let pickedSubject = $(event.target.parentNode).data('subject')
    let pickedTopic = $(event.target.parentNode).data('topic')
    let pickedLesson = $(event.target.parentNode).data('lesson')
    $(event.target).prop('disabled', true)

    $.ajax({
      type: 'post',
      url: '/quizzes',
      data: { quiz: { subject: pickedSubject, topic_id: pickedTopic, lesson_id: pickedLesson } },
      beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
      success: function (data) {
        Turbolinks.visit('/quizzes')
      }
    })
  })
})
