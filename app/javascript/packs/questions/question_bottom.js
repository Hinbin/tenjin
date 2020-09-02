$(document).on('turbolinks:load', function () {
  $('#unfairFlag').on('ajax:success', (event) => {
    if ($('#unfairFlag svg').data('prefix') === 'far') {
      $('#unfairFlag svg').addClass('fas')
      $('#feedbackModal').modal()
    } else {
      $('#unfairFlag svg').addClass('far')
    }
  })
})
