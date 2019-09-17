
$(document).on('turbolinks:load', () => {
  // Show updated password
  $(document).on('ajax:success', (event) => {
    const response = event.detail[0]
    $(`tr[data-id="${response.id}"] .reset-password`).replaceWith(`<div class="new-password">${response.password}</div>`)

  })

  // Data tables initialisation

  if (!$.fn.dataTable.isDataTable('#students-table')) {
    $('#students-table').DataTable({
      paging: true,
      dom: "<'row'<'col-sm-12 col-md-4 pt-4'B><'col-sm-12 col-md-4'l><'col-sm-12 col-md-4'f>>" +
        "<'row'<'col-sm-12'tr>>" +
        "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>",
      buttons: [
        'copyHtml5', 'csvHtml5', 'excelHtml5'
      ]
    })
  }

  if (!$.fn.dataTable.isDataTable('#employees-table')) {
    $('#employees-table').DataTable({
      paging: true,
      dom: "<'row'<'col-sm-12 col-md-4 pt-4'B><'col-sm-12 col-md-4'l><'col-sm-12 col-md-4'f>>" +
        "<'row'<'col-sm-12'tr>>" +
        "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>",
      buttons: [
        'copyHtml5', 'csvHtml5', 'excelHtml5'
      ]
    })
  }

  $('#confirmAllPasswordResetTextbox').off('input')

  $('#confirmAllPasswordResetTextbox').on('input', () => {
    const textBoxContents = $('#confirmAllPasswordResetTextbox').val()
    const schoolName = $('#schoolName').text()

    if (textBoxContents === schoolName) {
      $('#confirmAllPasswordResetButton').removeClass('disabled')
    } else {
      $('#confirmAllPasswordResetButton').addClass('disabled')
    }
  })
})

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
