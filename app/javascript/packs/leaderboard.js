// Load leaderboard with initial data
$(document).on('turbolinks:load', function () {
  if (page.controller() === 'leaderboard' && page.action() === 'show') {
    let leaderboard
    window.lb ? leaderboard = window.lb : leaderboard = new Leaderboard()
    window.lb = leaderboard
    leaderboard.optionSelected(null)
  }
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
    const path = window.gon.path + '.json?' + this.buildParams(id)
    $.ajax({
      type: 'GET',
      url: path,
      success: (result) => this.processResponse(result),
      error: (error) => this.processError(error)
    })
  }

  buildParams (id) {
    const schoolGroup = window.gon.params.school_group
    const allTime = window.gon.params.allTime
    let params = {}

    if (gon.topic !== undefined) {
      params.topic = window.gon.topic
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
    const myRow = 'tr#row-' + window.gon.user
    $(myRow).addClass('current-user')
  }

  sortLeaderboardTable () {
    this.allLeaderboardData.sort((a, b) => {
      // Sorts by scores, then by ranks if scores are the same
      let scoreComp = parseInt(b.score) - parseInt(a.score)
      if (scoreComp !== 0) {
        return scoreComp
      } else {
        // If scores are the same, sort alphabetically by first name
        if (a.name < b.name) { return -1 }
        if (a.name > b.name) { return 1 }
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
    let tableRows = $('#tableData tr')
    for (let i = 0; i < dataToDisplay.length; i++) {
      if (tableRows[i] === undefined) {
        table.append(this.buildRow(dataToDisplay[i], false))
      } else {
        let rowData = $(tableRows[i]).find('td')
        if (rowData[0] !== dataToDisplay[i].id) {
          $(tableRows[i]).replaceWith(this.buildRow(dataToDisplay[i], $(tableRows[i]).hasClass('score-changed')))
        }
      }
    }
  }

  buildRow (row, hasScoreFlash) {
    let tr

    if (hasScoreFlash === true) {
      tr = $('<tr>').attr('id', 'row-' + row.id).addClass('score-changed')
    } else {
      tr = $('<tr>').attr('id', 'row-' + row.id)
    }
    tr.append($('<td>').text(row.rank))
      .append($('<td>').text(row.name))

    if (row.icon && row.icon !== 'none') {
      let iconArray = row.icon.split(',')
      tr.append($('<td>').html(`<i class="fas fa-${iconArray[1]} fa" style="color: ${iconArray[0]}"></i>`))
    } else {
      tr.append($('<td>'))
    }

    tr.append($('<td>').attr('class', 'd-none d-sm-table-cell').text(row.school_name))
      .append($('<td>').text(Math.round(row.score)))

    return tr
  }

  snipTableData () {
    let tableData = this.allLeaderboardData
    const tableSize = tableData.length
    let userRowIndex = tableData.findIndex(x => x.id === window.gon.user)

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
      // If the user is too close to the bottom - display from the bottom of the table up
      return tableData.slice(tableSize - this.maxUsersToDisplay)
    } else {
      let lower = Math.max(0, userRowIndex - (this.maxUsersToDisplay / 2) + 1)
      let upper = Math.min(tableSize, lower + this.maxUsersToDisplay)
      return tableData.slice(lower, upper)
    }
  }

  scoreChanged (data, scoreType) {
    let found = false
    this.allLeaderboardData.map((x) => {
      if (x.id === data.id) {
        x.score = scoreType === 'TOPIC' ? data.topic_score : data.subject_score
        found = true
      }
    })

    if (found === false) {
      this.allLeaderboardData.push({
        id: data.id,
        name: data.name,
        rank: 0,
        school_name: data.school_name,
        score: scoreType === 'TOPIC' ? data.topic_score : data.subject_score
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
