$(document).on('turbolinks:load', function () {
  if ($('#notice').text().length) {
    $('#noticeModal').modal()
  }

  if ($('#alert').text().length) {
    $('#alertModal').modal()
  }
})
