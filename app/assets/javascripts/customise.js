
function buyCustomisation (button) {
  let form = $('#customisation')
  let buttonData = $(button).data()
  console.log(buttonData)
  $('#customisation-type').val(buttonData['customisationType'])
  $('#customisation-value').val(buttonData['value'])
  console.log(form)
  form.submit()
}
