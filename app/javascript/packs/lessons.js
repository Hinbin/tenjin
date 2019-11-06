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

  $('img[category="vimeo"]').each((i, video) => {
    let vimeoVideoID = $(video).attr('video_id')
    $.getJSON('https://www.vimeo.com/api/v2/video/' + vimeoVideoID + '.json?callback=?',
      { format: 'json' }, function (data) {
        $(video).attr('src', data[0].thumbnail_large)
      })
  })
})
