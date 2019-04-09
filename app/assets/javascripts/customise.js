$(document).on('turbolinks:load', () => {
  if (page.controller() === 'customise' && page.action() === 'show') {
    $('.dashboard-buy-btn').click((event) => {
      let form = $('#customisation')
      let buttonData = $(event.target).data()
      $('#customisation-type').val(buttonData['customisationType'])
      $('#customisation-value').val(buttonData['value'])
      form.submit()
    })
  }
})
