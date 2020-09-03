
$(document).on('turbolinks:load', function () {
  if (typeof gtag === 'function') {
    gtag('config', '<%= ENV[GOOGLE_ANALYTICS_ID] %>', {
      'page_location': event.data.url
    })
  }
})