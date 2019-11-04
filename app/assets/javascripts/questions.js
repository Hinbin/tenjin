$(document).on('turbolinks:load', () => {
  if (page.controller() === 'questions' && page.action() === 'show') {
    $('#questionTypeSelect').change(function () {
      let pickedType = $(this).val()

      $.ajax({
        type: 'put',
        url: window.location.pathname,
        beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
        data: { question: { question_type: pickedType } },
        success: function (data) {
          location.reload()
        }
      })
    })

    $('trix-editor').on('trix-blur', (event) => {
      saveQuestionText(() => {})
    })

    $('.check-and-save').click((event) => {
      const questionTopicIndexLocation = $(event.target).data()

      validateAndSave(() => { Turbolinks.visit(questionTopicIndexLocation['link']) })
    })
  }
})

function validateAndSave (successCallback) {
  const correctAnswers = $('input[checked=checked]')

  // If not answers have been selected as correct, and we're trying to save...
  if (correctAnswers.length === 0 && $('#questionTypeSelect').val() !== 'short_answer') {
    // Alert the user and do not save.
    $('#noCorrectAnswerModal').modal()
  } else {
    // Else save the question text and return
    saveQuestionText(successCallback)
  }
}

function saveQuestionText (successCallback) {
  const questionText = $('#question_question_text').val()

  $.ajax({
    type: 'put',
    url: window.location.pathname,
    beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
    data: { question: { question_text: questionText } },
    success: successCallback()
  })
}
