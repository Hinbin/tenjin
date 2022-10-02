$(document).on('turbo:load', () => {

  $('tr[data-classroom]').click((event) => {
    const pickedClassroom = $(event.target.parentNode).data('classroom')
    if (event.target.classList.contains('btn')) return

    Turbo.visit('/classrooms/' + pickedClassroom)
  })

  if (!$.fn.dataTable.isDataTable('#otherClassroomTable')) {
    $('#otherClassroomTable').DataTable({
      'pageLength': 25,
      'language': {
        'emptyTable': 'No other classrooms have been found'
      }
    })
  }
})

$(document).on('turbo:before-cache', () => {
  $('tr[data-controller]').off('click')
  $('#otherClassroomTable').DataTable().destroy()
})
