function processMultipleChoiceResponse (results, guess) {
  const guessDiv = '#' + guess

  var correct = false
  for (var result of results) {
    const resultID = '#response-' + result.id

    $(resultID).addClass('correct-answer')
    if (resultID === guessDiv) {
      correct = true
      $(guessDiv).append('<i class="fas fa-check fa-lg float-right my-1"></i>')
    }
  }

  if (!correct) {
    $(guessDiv).addClass('incorrect-answer')
    $(guessDiv).append('<i class="fas fa-times fa-lg float-right my-1"></i>')
  }

  $('#nextButton').removeClass('invisible')
  $('#nextButton').focus()
}

$(document).on('turbolinks:load', function () {
  $('.multiple-choice-button').click((click) => {
    if ($(click.target).hasClass('disabled')) {
      return
    }

    $('.multiple-choice-button').attr('disabled', 'disabled')
    $('.multiple-choice-button').addClass('disabled')

    $.ajax({
      type: 'PUT',
      url: '/quizzes/' + window.gon.quiz_id,
      success: (result) => processMultipleChoiceResponse(result, click.target.id),
      data: {
        answer: {
          id: click.target.id.slice(9)
        }
      }
    })
  })
})
