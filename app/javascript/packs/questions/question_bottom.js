$(document).on('turbolinks:load', function () {
  $('#unfairFlag').on('ajax:success', (event) => {
    $('#unfairFlag i').toggleClass('fas')
    $('#unfairFlag i').toggleClass('far')

    if ($('#unfairFlag i').hasClass('fas')) {
      $('#feedbackModal').modal()
    }
  })
})
