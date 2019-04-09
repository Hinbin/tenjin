$(document).on('turbolinks:load', () => {
  if (page.controller() === 'questions' && page.action() === 'show') {
    $('#questionTypeSelect').change(function () {
      let pickedType = $(this).val()

      $.ajax({
        type: 'put',
        url: window.location.pathname,
        data: { question: { question_type: pickedType } },
        success: function (data) {
          location.reload()
        }
      })
    })

    $('trix-editor').on('trix-blur', (event) => {
      const questionText = $(event.target).val()

      $.ajax({
        type: 'put',
        url: window.location.pathname,
        data: { question: { question_text: questionText } },
        success: function (data) {
          console.log('Saved')
        }
      })
    })

    $('#saveAndReturn').click((event) => {
      const questionText = $('#question_question_text').val()
      const questionTopicIndexLocation = $(event.target).data()

      $.ajax({
        type: 'put',
        url: window.location.pathname,
        data: { question: { question_text: questionText } },
        success: function (data) {
          Turbolinks.visit(questionTopicIndexLocation['topic'])
        }
      })
    })
  }
})
