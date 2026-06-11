$(document).on('turbo:load', function () {
  if (page.controller() === 'pages' && page.action() === 'show') {
    if (location.href.indexOf('about') === -1) {
      $('#navbar-main').addClass('tj-navbar--fixed')
      $('#navbar-main').removeClass('tj-navbar--dark')
    } else {
      $('#navbar-main').removeClass('tj-navbar--fixed')
      $('#navbar-main').addClass('tj-navbar--dark')
    }
  }
})
