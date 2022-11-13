
$(document).on('turbo:load', () => {
  if (page.controller() === 'users' || page.controller() === 'schools') {
    // Data tables initialisation
    if (!$.fn.dataTable.isDataTable('#students-table')) {
      $('#students-table').DataTable({
        paging: true,
        dom: "<'row'<'col-sm-12 col-md-4 pt-4'B><'col-sm-12 col-md-4'l><'col-sm-12 col-md-4'f>>" +
          "<'row'<'col-sm-12'tr>>" +
          "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>",
        buttons: [
          'copyHtml5', 'csvHtml5', 'excelHtml5'
        ],
        order: [[3, 'asc'], [0, 'asc']]
      })
    }

    if (!$.fn.dataTable.isDataTable('#users-table')) {
      $('#users-table').DataTable({
        paging: true
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
  }
})

$(document).on('turbo:before-cache', () => {
  $('#employees-table').DataTable().destroy()
  $('#students-table').DataTable().destroy()
  $('#users-table').DataTable().destroy()
})
