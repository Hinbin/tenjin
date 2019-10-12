$(document).on('turbolinks:load', function () {
  if (page.controller() === 'schools') {
    $('.select_input').on('change', (change) => {
      var subjectMapId = change.target.id
      var subjectPicked = $(change.target).children('option:selected').text()
      $(change.target).attr('disabled', 'disabled')

      $.ajax({
        type: 'PUT',
        url: '/subject_maps/' + subjectMapId,
        beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
        success: () => { $(change.target).removeAttr('disabled') },
        data: {
          subject_map: {
            name: subjectPicked
          }
        }
      })
    })
  }
})

