$(document).on('turbolinks:load', () => {
  flatpickr('.datepicker', { enableTime: true, minDate: new Date(), time_24hr: true })
})

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
