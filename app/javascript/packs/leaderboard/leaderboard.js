let allLeaderboardData = []
let top50 = false
const maxUsersToDisplay = 10
const gon = window.gon

// Load leaderboard with initial data
$(document).ready(function () {
  optionSelected(null)
})

function enableOptionButtons () {
  // Setup on-click events
  $('.option-label').removeClass('disabled')
  $('.option-label').on('click', (click) => {
    optionSelected($(click.target))
  })
}

function optionSelected (_this) {
  let id = _this === null ? null : _this.attr('id')
  disableOptionButtons()
  $('#tableData').html('')
  if (id === 'top50' || id === 'myPosition') {
    top50 = id === 'top50'
    showLeaderboardData()
    highlightUser()
    enableOptionButtons()
  } else {
    showLoadingSpinner()
    getData(id)
  }
}

function disableOptionButtons () {
  $('.option-label').addClass('disabled')
  $('.option-label').off('click')
}

function showLoadingSpinner () {
  $('#loading').removeClass('invisible')
  console.log('show loading')
}

function hideLoadingSpinner () {
  $('#loading').addClass('invisible')
}

function getData (id) {
  const path = gon.path + '.json' + buildParams(id)
  $.ajax({
    type: 'GET',
    url: path,
    success: (result) => processResponse(result),
    error: (error) => processError(error)
  })
}

function buildParams (id) {
  const schoolGroup = gon.params.school_group
  let params = '?'

  if (id === 'schoolGroup' || schoolGroup) {
    params = params + 'school_group=true'
  }

  return params
}

function processError (result) {
  console.log('error!')
  hideLoadingSpinner()
  enableOptionButtons()
}

function processResponse (result) {
  allLeaderboardData = result['leaderboard']
  sortLeaderboardTable()
  showLeaderboardData()
  highlightUser()
  hideLoadingSpinner()
  enableOptionButtons()
}

function highlightUser () {
  const myRow = 'tr#row-' + gon.user
  $(myRow).addClass('bg-dark text-light')
}

function sortLeaderboardTable () {
  allLeaderboardData.sort((a, b) => {
    // Sorts by scores, then by ranks if scores are the same
    let scoreComp = parseInt(b.score) - parseInt(a.score)
    if (scoreComp !== 0) {
      return scoreComp
    } else {
      return parseInt(a.rank) - parseInt(b.rank)
    }
  })

}

function showLeaderboardData () {

  const dataToDisplay = snipTableData(allLeaderboardData)

  let table = $('tbody')
  dataToDisplay.map((row) => {
    table.append($('<tr>').attr('id', 'row-' + row.user_id)
      .append($('<td>').text(row.rank))
      .append($('<td>').text(row.forename + ' ' + row.surname))
      .append($('<td>').text(row.school_name))
      .append($('<td>').text(row.score))
    )
  })
}

function snipTableData (tableData) {
  const tableSize = tableData.length
  let userRowIndex = tableData.findIndex(x => x.user_id === gon.user)

  if (top50) {
    return tableData.slice(0, 50)
  }

  // If there aren't enough users to fill the table, show the whole table
  if (tableSize < (maxUsersToDisplay - 1)) {
    console.log('Not enough data, showing all')
    return tableData
  }
  // If the user is close enough to the top of the table, display the top only
  else if (userRowIndex < maxUsersToDisplay) {
    console.log('Too close to the top, showing all')
    return tableData.slice(0, (maxUsersToDisplay))
    // Otherwise snip the 5 around the user
  }
  else if ((userRowIndex + (maxUsersToDisplay / 2)) > tableSize) {
    return tableData.slice(userRowIndex - maxUsersToDisplay + 1, userRowIndex + 1)

  }
  else {
    let lower = Math.max(0, userRowIndex - (maxUsersToDisplay / 2) + 1)
    let upper = Math.min(tableSize, lower + maxUsersToDisplay)
    console.log(lower, upper, userRowIndex, maxUsersToDisplay, tableSize)
    return tableData.slice(lower, upper)
  }
}