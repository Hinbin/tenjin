$(document).on("turbolinks:load", () => {
  flatpickr(".datepicker", {
    enableTime: true,
    minDate: new Date(),
    time_24hr: true,
  });
});
