const gon = window.gon

// Load leaderboard with initial data
$(document).ready(function () {
  let leaderboard = new Leaderboard()
  leaderboard.optionSelected(null)
  window.leaderboard = leaderboard
})

class Leaderboard {
  constructor () {
    this.allLeaderboardData = []
    this.top50 = false
    this.maxUsersToDisplay = 10
  }

  enableOptionButtons () {
    // Setup on-click events
    $('.option-label').removeClass('disabled')
    $('.option-label').on('click', (click) => {
      this.optionSelected($(click.target))
    })
  }

  optionSelected (_this) {
    let id = _this === null ? null : _this.attr('id')
    this.disableOptionButtons()
    $('#tableData').html('')
    if (id === 'top50' || id === 'myPosition') {
      this.top50 = id === 'top50'
      this.showLeaderboardData()
      this.highlightUser()
      this.enableOptionButtons()
    } else {
      this.showLoadingSpinner()
      this.getData(id)
    }
  }
  disableOptionButtons () {
    $('.option-label').addClass('disabled')
    $('.option-label').off('click')
  }

  showLoadingSpinner () {
    $('#loading').removeClass('invisible')
  }

  hideLoadingSpinner () {
    $('#loading').addClass('invisible')
  }

  getData (id) {
    const path = gon.path + '.json?' + this.buildParams(id)
    $.ajax({
      type: 'GET',
      url: path,
      success: (result) => this.processResponse(result),
      error: (error) => this.processError(error)
    })
  }

  buildParams (id) {
    const schoolGroup = gon.params.school_group
    const allTime = gon.params.allTime
    let params = {}

    if (gon.topic !== undefined) {
      params.topic = gon.topic
    }

    if (id === 'schoolGroup' || schoolGroup) {
      params.school_group = true
    }

    if (id === 'allTime' || allTime) {
      params.all_time = true
    }

    return jQuery.param(params)
  }

  processError (result) {
    this.hideLoadingSpinner()
    this.enableOptionButtons()
  }

  processResponse (result) {
    this.allLeaderboardData = result['leaderboard']
    this.sortLeaderboardTable()
    this.showLeaderboardData()
    this.highlightUser()
    this.hideLoadingSpinner()
    this.enableOptionButtons()
  }

  highlightUser () {
    const myRow = 'tr#row-' + gon.user
    $(myRow).addClass('bg-dark text-light')
  }

  sortLeaderboardTable () {
    this.allLeaderboardData.sort((a, b) => {
      // Sorts by scores, then by ranks if scores are the same
      let scoreComp = parseInt(b.score) - parseInt(a.score)
      if (scoreComp !== 0) {
        return scoreComp
      } else {
        // If scores are the same, sort alphabetically by first name
        if (a.forename < b.forename) { return -1 }
        if (a.forename > b.forename) { return 1 }
        return 0
      }
    })
    // Now they're sorted, re-rank them
    for (var i = 0; i < this.allLeaderboardData.length; i++) {
      this.allLeaderboardData[i].rank = i + 1
    }
  }

  showLeaderboardData () {
    const dataToDisplay = this.snipTableData()

    let table = $('#tableData')
    table.children('tr').remove()
    dataToDisplay.map((row) => {
      table.append($('<tr>').attr('id', 'row-' + row.id)
        .append($('<td>').text(row.rank))
        .append($('<td>').text(row.forename + ' ' + row.surname))
        .append($('<td>').attr('class', 'd-none d-sm-table-cell').text(row.school_name))
        .append($('<td>').text(Math.round(row.score))))
    })
  }

  snipTableData () {
    let tableData = this.allLeaderboardData
    const tableSize = tableData.length
    let userRowIndex = tableData.findIndex(x => x.id === gon.user)

    if (this.top50) {
      return tableData.slice(0, 50)
    }

    if (tableSize < (this.maxUsersToDisplay - 1)) {
      // If there aren't enough users to fill the table, show the whole table
      return tableData
    } else if (userRowIndex < this.maxUsersToDisplay) {
      // If the user is close enough to the top of the table, display the top only
      return tableData.slice(0, (this.maxUsersToDisplay))
      // Otherwise snip the 5 around the user
    } else if ((userRowIndex + (this.maxUsersToDisplay / 2)) > tableSize) {
      return tableData.slice(userRowIndex - this.maxUsersToDisplay + 1, userRowIndex + 1)
    } else {
      let lower = Math.max(0, userRowIndex - (this.maxUsersToDisplay / 2) + 1)
      let upper = Math.min(tableSize, lower + this.maxUsersToDisplay)
      return tableData.slice(lower, upper)
    }
  }

  scoreChanged (data) {
    let found = false
    this.allLeaderboardData.map((x) => {
      if (x.id === data.id) {
        x.score = data.subject_score
        found = true
      }
    })

    if (found === false) {
      this.allLeaderboardData.push({
        id: data.id,
        forename: data.forename,
        surname: data.surname,
        rank: 0,
        school_name: data.school_name,
        score: data.score
      })
    }

    this.sortLeaderboardTable()
    this.showLeaderboardData()
    this.highlightUser()
    this.flashScore(data.id)
  }

  flashScore (userID) {
    let scoreRow = $('#row-' + userID)

    // Updates the table and adds the score-changed class to cause
    // the row to flash
    $(scoreRow).addClass('score-changed')

    setTimeout(() => {
      $(scoreRow).removeClass('score-changed')
    }, 1010)
  }
}
