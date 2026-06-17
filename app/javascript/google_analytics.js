document.addEventListener('turbo:load', (event) => {
  if (typeof gtag === 'function') {
    gtag('config', '<%= ENV[GOOGLE_ANALYTICS_ID] %>', {
      page_location: event.detail?.url
    })
  }
})
