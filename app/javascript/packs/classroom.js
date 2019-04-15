$(document).on('turbolinks:load', () => {

  $('tr[data-homework]').click( (event) => {
    const pickedHomework = $(event.target.parentNode).data('homework')
    Turbolinks.visit('/homeworks/' + pickedHomework)
  })

})

if (!Turbolinks) {
  location.reload()
}

Turbolinks.dispatch('turbolinks:load')
