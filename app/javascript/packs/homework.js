$(document).on('turbo:load', () => {
  flatpickr('.datepicker', { enableTime: true, minDate: new Date(), time_24hr: true })
})