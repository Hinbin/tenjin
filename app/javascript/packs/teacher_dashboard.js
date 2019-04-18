$(document).on('turbolinks:load', () => {

  $('tr[data-classroom]').off('click')

  $('tr[data-classroom]').click( (event) => {
    const pickedClassroom = $(event.target.parentNode).data('classroom')
    Turbolinks.visit('/classrooms/' + pickedClassroom)
  })

})

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
