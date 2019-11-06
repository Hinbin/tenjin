$(document).on('turbolinks:load', () => {

  if (page.controller() === 'questions') {
 
    if (!$.fn.dataTable.isDataTable('#questionTable')) {
      $('#questionTable').DataTable({
        'pageLength': 50,
        'language': {
          'emptyTable': 'No questions have been found'
        }
      })
    }

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
      const paths = $(event.target).data()

      validateAndSave(() => { Turbolinks.visit(paths['redirect']) }, paths['update'])
    })
  }
})

function validateAndSave (successCallback, updatePath) {
  const correctAnswers = $('input[checked=checked]')

  // If not answers have been selected as correct, and we're trying to save...
  if (correctAnswers.length === 0 && $('#questionTypeSelect').val() !== 'short_answer') {
    // Alert the user and do not save.
    $('#noCorrectAnswerModal').modal()
  } else {
    // Else save the question text and return
    saveQuestionText(successCallback, updatePath)
  }
}

function saveQuestionText (successCallback, updatePath) {
  const questionText = $('#question_question_text').val()

  $.ajax({
    type: 'put',
    url: updatePath,
    beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
    data: { question: { question_text: questionText } },
    success: successCallback()
  })
}
