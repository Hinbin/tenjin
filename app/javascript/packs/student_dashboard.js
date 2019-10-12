$(document).on('turbolinks:load', () => {

  $('.challenge-row, .homework-row').off('click')

  $('.challenge-row, .homework-row').click(function (event) {
    let pickedSubject = $(event.target.parentNode).data('subject')
    let pickedTopic = $(event.target.parentNode).data('topic')
    $(event.target).prop('disabled', true)

    $.ajax({
      type: 'post',
      url: '/quizzes',
      data: { quiz: { subject: pickedSubject, topic_id: pickedTopic } },
      beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
      success: function (data) {
        Turbolinks.visit('/quizzes')
      }
    })
  })
})
