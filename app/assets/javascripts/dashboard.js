$(document).on('ready turbolinks:load', () => {

  $('#challenge-table tr').click(function () {
    let pickedSubject = $(this).data('subject')
    let pickedTopic = $(this).data('topic')

    $.ajax({
      type: 'post',
      url: '/quizzes',
      data: { quiz: { subject: pickedSubject, picked_topic: pickedTopic } },
      success: function (data) {
        Turbolinks.visit('/quizzes')
      }
    })
  })

  $('.subject-carousel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 1,
    nextArrow: '<div class="slick-prev"><i class="fa fa-angle-right fa-fw"></i></div>',
    prevArrow: '<div class="slick-next"><i class="fa fa-angle-left fa-fw"></i></div>',
    responsive: [
      {
        breakpoint: 992,
        settings: {
          slidesToShow: 2
        }
      },
      {
        breakpoint: 768,
        settings: {
          slidesToShow: 1
        }
      }
    ]
  })
})
