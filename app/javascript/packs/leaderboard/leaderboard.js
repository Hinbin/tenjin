let allLeaderboardData = []
const maxUsersToDisplay = 10

$(document).on('turbolinks:load', function () {
  const myRow = 'tr#row-' + gon.user
  $(myRow).addClass('bg-dark text-light')
  allLeaderboardData = Array.from($('tbody').find('tr'))
  sortLeaderboardTable()
})

function sortLeaderboardTable () {
  allLeaderboardData.sort((a, b) => {
    // Sorts by scores, then by ranks if scores are the same
    let scoreComp = parseInt(b.childNodes[3].textContent) - parseInt(a.childNodes[3].textContent)
    if (scoreComp !== 0) {
      return scoreComp
    } else {
      return parseInt(a.childNodes[0].textContent) - parseInt(b.childNodes[0].textContent)
    }
  })

  updateVisibleLeaderboard()
}

function updateVisibleLeaderboard () {
  let table = $('tbody')
  $(table).html(snipTableData(allLeaderboardData))
}

function snipTableData (tableData) {
  const tableSize = tableData.length
  let userRowIndex = tableData.findIndex(x => x.id === 'row-' + gon.user)

  // If there aren't enough users to fill the table, show the whole table
  if (tableSize < (maxUsersToDisplay - 1)) {
    return tableData
  }
  // If the user is close enough to the top of the table, display the top only
  else if (userRowIndex < maxUsersToDisplay) {
    return tableData.slice(0, (maxUsersToDisplay))
  // Otherwise snip the 5 around the user
  } else {
    let lower = Math.max(0, userRowIndex - maxUsersToDisplay + 1)
    let upper = Math.min(tableSize, lower + maxUsersToDisplay)
    return tableData.slice(lower, upper)
  }
}
