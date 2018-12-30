
function processResponse(results, guess) {  
  var correct = false
  for (var result of results) {
    const resultID = '#response-' + result.id
    $(resultID).addClass('correct-answer')
    if ( resultID.slice(1) === guess )
      correct = true
  }

  if (!correct) {
    $('#'+ guess).addClass('incorrect-answer')
  }

  $('#nextButton').removeClass('invisible')
  $('#nextButton').focus()
}

$(document).on('turbolinks:load', function () {

  $('.question-button').click( (click) => {   

    if ( $(click.target).hasClass('disabled') )
      return
    
    $('.question-button').attr('disabled', 'disabled')
    $('.question-button').addClass('disabled')

    $.ajax({
      type: 'PUT',
      url: '/quizzes/' + gon.quiz_id ,
      success: (result) => processResponse(result, click.target.id),
      data: {
        answer: {
            id: click.target.id.slice(9)
          }
      }
    })
  })
})
