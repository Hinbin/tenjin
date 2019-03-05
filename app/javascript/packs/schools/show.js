// Add a listener for each select box to post to the subject map
// the correct subject ID


$(document).on('turbolinks:load', function () {

  $('.select_input').on('change', (change) => {
    var subject_map_id = change.target.id
    var subject_picked = $(change.target).children("option:selected").text();
    $(change.target).attr('disabled', 'disabled')

    $.ajax({
      type: 'PUT',
      url: '/subject_maps/' + subject_map_id,
      success: () => { $(change.target).removeAttr('disabled') },
      data: {
        subject_map: {
          name: subject_picked,
        }
      }
    })
  })
})

