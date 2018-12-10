
function processResponse(results, guess) {  
  var correct = false
  for (var result of results) {
    $('#' + result.id).addClass('correct-answer')
    if ( result.id == guess )
      correct = true
  }

  if (!correct) {
    $('#' + guess).addClass('incorrect-answer')
  }

  $('#nextButton').removeClass('invisible')
  $('#nextButton').focus()
}

$(document).on('turbolinks:load', function () {

  $('.question-button').click( (click) => {   
    
    $('.question-button').attr('disabled', 'disabled')
    $('.question-button').addClass('disabled')

    $.ajax({
      type: 'PUT',
      url: '/quizzes/' + gon.quiz_id ,
      success: (result) => processResponse(result, click.target.id),
      data: {
        answer: {
            id: click.target.id
          }
      }
    })
  })
})
