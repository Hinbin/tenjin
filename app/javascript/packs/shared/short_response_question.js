
function processResponse(results, guess) {  
  var correct = false
  for (var result of results) {
    if ( result.text == guess ) {
      $('#shortAnswerButton').addClass('correct-answer')
      $('#shortAnswerButton').text('Correct!')
      correct = true
    }
  }

  if (!correct) {
    $('#shortAnswerButton').addClass('incorrect-answer')
    $('#shortAnswerButton').text('Incorrect')

    $('#shortAnswerText').addClass('correct-answer')
    $('#shortAnswerText').val(results[0].text)
  }

  $('#nextButton').removeClass('invisible')
  $('#nextButton').focus()
  

  
}

$(document).on('turbolinks:load', function () {
 
  // If someone presses enter, cause the submit answer button to be pressed
  $('#shortAnswerText').keypress( (e) => {
    if(e.keyCode==13)
      $('#shortAnswerButton').click();
  });


  $('#shortAnswerButton').click( (click) => {   

    $('#shortAnswerButton').attr('disabled', 'disabled')
    $('#shortAnswerText').attr('disabled', 'disabled')

    $.ajax({
      type: 'PUT',
      url: '/quizzes/' + gon.quiz_id ,
      success: (result) => processResponse(result, $('#shortAnswerText').val()),
      data: {
        answer: {
            short_answer: $('#shortAnswerText').val()
          }
      }
    })
  })
})
