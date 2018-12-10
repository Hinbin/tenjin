$(document).on('turbolinks:load', function () {

  $('.question-button').click( (click) => {   
    
    data = {       
      data: {
        answer_ids: {
          id: click.target.id
        }
      }
    }
    $('.question-button').attr('disabled', 'disabled')

    console.log(data)
    $.ajax({
      type: 'PUT',
      url: '/quizzes/5',
      success: () => { $(click.target).removeAttr('disabled')},
      data: {
        question: {
          answer_ids: {
            id: click.target.id
          }
        }
      }
    })
  })
})
