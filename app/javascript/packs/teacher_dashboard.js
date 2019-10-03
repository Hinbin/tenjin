$(document).on('turbolinks:load', () => {
  $('tr[data-classroom]').off('click')

  $('tr[data-classroom]').click((event) => {
    const pickedClassroom = $(event.target.parentNode).data('classroom')
    if (event.target.classList.contains('btn')) return

    Turbolinks.visit('/classrooms/' + pickedClassroom)
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

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
