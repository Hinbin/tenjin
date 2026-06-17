document.addEventListener('turbo:load', () => {
  if (page.controller() !== 'pages' || page.action() !== 'show') return

  const navbar = document.getElementById('navbar-main')
  if (!navbar) return

  if (location.href.indexOf('about') === -1) {
    navbar.classList.add('tj-navbar--fixed')
    navbar.classList.remove('tj-navbar--dark')
  } else {
    navbar.classList.remove('tj-navbar--fixed')
    navbar.classList.add('tj-navbar--dark')
  }
})
