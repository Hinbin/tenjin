
$(document).on('turbolinks:load', function () {
  let table = $('#leaderboardTable').stupidtable()

  $('#scoreColumn').stupidsort();

  table.bind('aftertablesort', function (event, data) {
    $('#tableContainer').removeClass('invisible')
  })

})
