$(document).on('turbolinks:load', function () {
  if (page.controller() === 'pages' && page.action() === 'show') {
    if (location.href.indexOf('about') === -1) {
      $('#navbar-main').addClass('fixed-top')
      $('#navbar-main').removeClass('bg-dark')
    } else {
      $('#navbar-main').removeClass('fixed-top')
      $('#navbar-main').addClass('bg-dark')
    }
  }
})
