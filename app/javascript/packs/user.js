$('.edit_user').bind('ajax:beforeSend', function () {
  $('.page-section-header').text('Sending')
})

$('.edit_user').bind('ajax:complete', function () {
  $('.page-section-header').text('Changed')
})
