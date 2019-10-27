$(document).on('turbolinks:load', () => {
  $('.videoLink').click((click) => {
    var $videoSource = $(click.currentTarget).attr('src')
    $('iframe#video').attr('src', $videoSource + '?autoplay=1&rel=0')
  })

  // stop playing the youtube video when I close the modal
  $('#videoModal').on('hide.bs.modal', function (e) {
    // a poor man's stop video
    $('iframe#video').attr('src', $('iframe#video').attr('src').replace('autoplay=1', 'autoplay=0'))
  })
})
