import { Controller } from '@hotwired/stimulus'
import consumer from '../../channels/consumer'

const maxUsersToDisplay = 10

export default class extends Controller {
  connect () {
    this.loading = true
    this.initialLeaderboard = {}
    this.weeklyLeaderboard = {}
    this.allTimeLeaderboard = {}
    this.currentLeaderboard = {}
    this.currentFilters = []
    this.filters = {}
    this.schools = []
    this.classrooms = []
    this.user = {}
    this.showAll = false
    this.allTime = false
    this.allSchoolsLoaded = false
    this.live = false
    this.name = ''
    this.winners = []
    this.connected = false
    this.flashTimers = {}
    this.subscription = null

    this.url = this.data.get('url')
    this.subject = this.data.get('subject')
    this.school = this.data.get('school')
    this.schoolGroup = this.data.get('schoolGroup')
    this.topic = this.data.get('topic')

    this.listenToLeaderboard()
    this.loadLeaderboard()
  }

  disconnect () {
    if (this.subscription) this.subscription.unsubscribe()
    Object.values(this.flashTimers).forEach((timer) => clearTimeout(timer))
  }

  listenToLeaderboard () {
    if (!this.subject || !this.school) return

    this.subscription = consumer.subscriptions.create({
      channel: 'LeaderboardChannel',
      subject: this.subject,
      school: this.school,
      school_group: this.schoolGroup
    }, {
      connected: () => {
        this.connected = true
        this.render()
      },
      disconnected: () => {
        this.connected = false
        this.render()
      },
      received: (data) => {
        if (!this.topic || String(data.topic) === String(this.topic)) {
          this.leaderboardChange(data)
        }
      }
    })
  }

  loadLeaderboard () {
    this.loading = true
    this.render()

    return window.fetch(this.leaderboardUrl(), {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then((response) => response.json())
      .then((result) => {
        this.processLeaderboardLoad(result)
        this.processScores()
        this.processFilterLoad(result)
        this.loading = false
        this.render()
      })
      .catch((error) => {
        this.loading = false
        console.log(error)
        this.render()
      })
  }

  leaderboardUrl () {
    const url = new URL(this.url, window.location.origin)

    if (this.topic) url.searchParams.set('topic', this.topic)
    if (this.loadingSchoolGroup) url.searchParams.set('school_group', 'true')
    if (this.allTime) url.searchParams.set('all_time', 'true')

    return url.toString()
  }

  processLeaderboardLoad (result) {
    const leaderboard = {}
    result.leaderboard.forEach((userData) => {
      leaderboard[userData.id] = { ...userData }
    })

    if (this.allTime) {
      this.allTimeLeaderboard = leaderboard
    } else {
      this.weeklyLeaderboard = leaderboard
      this.initialLeaderboard = { ...this.weeklyLeaderboard }
    }

    this.name = result.name
    this.user = result.user
    this.winners = result.winners
  }

  processScores () {
    if (this.allTime) {
      this.currentLeaderboard = JSON.parse(JSON.stringify(this.weeklyLeaderboard))
      Object.keys(this.allTimeLeaderboard).forEach((id) => this.calculateAllTimeScore(id))
    } else if (!this.live) {
      this.currentLeaderboard = JSON.parse(JSON.stringify(this.weeklyLeaderboard))
    }
  }

  calculateAllTimeScore (id) {
    if (this.currentLeaderboard[id]) {
      const weeklyScore = parseInt(this.weeklyLeaderboard[id].score, 10) || 0
      const allTimeScore = parseInt(this.allTimeLeaderboard[id].score, 10) || 0
      this.currentLeaderboard[id].score = weeklyScore + allTimeScore
    } else {
      this.currentLeaderboard[id] = { ...this.allTimeLeaderboard[id] }
    }
  }

  processFilterLoad (result) {
    this.schools = result.schools
    this.classrooms = result.classrooms

    const filters = {}
    filters.classroom = {
      name: 'Class',
      options: ['All'].concat(this.classrooms),
      default: 'Select Class'
    }

    if (this.schools.length > 1) {
      filters.schools = {
        name: 'Schools',
        options: ['All'].concat(this.schools),
        default: 'Select School'
      }
    }

    this.filters = filters
  }

  toggleLive (event) {
    this.live = event.target.checked

    if (this.live) {
      this.showAll = true
      this.allTime = false
      if (this.schools.length > 1) {
        this.setFilter('Schools', 'All')
      } else {
        this.initialLeaderboard = { ...this.weeklyLeaderboard }
      }
      this.currentLeaderboard = {}
    } else {
      this.processScores()
    }

    this.render()
  }

  toggleShowAll (event) {
    this.showAll = event.target.checked
    this.render()
  }

  toggleAllTime (event) {
    this.allTime = event.target.checked

    if (this.allTime && Object.keys(this.allTimeLeaderboard).length === 0) {
      this.loadLeaderboard()
    } else {
      this.processScores()
      this.render()
    }
  }

  selectFilter (event) {
    event.preventDefault()
    this.setFilter(event.currentTarget.dataset.filterName, event.currentTarget.dataset.filterOption)
    this.render()
  }

  setFilter (name, option) {
    this.currentFilters = this.currentFilters.filter((filter) => filter.name !== name)
    this.currentFilters.push({ name: name, option: option })

    if (name === 'Schools') {
      this.currentFilters = this.currentFilters.filter((filter) => filter.name === 'Schools')
      this.loadingSchoolGroup = true
      if (!this.allSchoolsLoaded) {
        this.allSchoolsLoaded = true
        this.loadLeaderboard()
      }
    }

    if (name === 'Class') {
      this.currentFilters = this.currentFilters.filter((filter) => filter.name === 'Class')
    }
  }

  leaderboardChange (data) {
    const id = data.id
    let score = this.topic ? data.topic_score : data.subject_score

    if (this.live && this.initialLeaderboard[id]) {
      score -= this.initialLeaderboard[id].score
    }

    this.currentLeaderboard[id] = { ...this.currentLeaderboard[id], ...data, score: score, lastChanged: true }
    this.render()

    if (this.flashTimers[id]) clearTimeout(this.flashTimers[id])
    this.flashTimers[id] = setTimeout(() => {
      if (this.currentLeaderboard[id]) {
        this.currentLeaderboard[id].lastChanged = false
        this.render()
      }
    }, 1000)
  }

  sortedLeaderboard () {
    let sortedLeaderboard = Object.keys(this.currentLeaderboard)
      .map((id) => this.currentLeaderboard[id])
      .filter((entry) => this.checkFilters(entry))
      .sort((a, b) => b.score - a.score)
      .map((entry, index) => ({ ...entry, position: index + 1 }))

    if (!this.showAll) sortedLeaderboard = this.snipTableData(sortedLeaderboard)

    return sortedLeaderboard
  }

  snipTableData (tableData) {
    const tableSize = tableData.length
    const userRowIndex = tableData.findIndex((entry) => entry.id === this.user.id)

    if (tableSize < (maxUsersToDisplay - 1)) {
      return tableData
    } else if (userRowIndex < maxUsersToDisplay) {
      return tableData.slice(0, maxUsersToDisplay)
    } else if ((userRowIndex + (maxUsersToDisplay / 2)) > tableSize) {
      return tableData.slice(tableSize - maxUsersToDisplay)
    } else {
      const lower = Math.max(0, userRowIndex - (maxUsersToDisplay / 2) + 1)
      const upper = Math.min(tableSize, lower + maxUsersToDisplay)
      return tableData.slice(lower, upper)
    }
  }

  checkFilters (entry) {
    const userSchool = this.user.school
    let schoolFilterSet = false

    for (const filter of this.currentFilters) {
      if (filter.name === 'Schools' && filter.option !== 'All' && entry.school_name !== filter.option) return false
      if ((filter.name === 'Class' && filter.option !== 'All') &&
          ((entry.classroom_names === null || !entry.classroom_names.includes(filter.option)) ||
          entry.school_name !== userSchool)) return false
      if (filter.name === 'Schools') schoolFilterSet = true
    }

    if (!schoolFilterSet && entry.school_name !== userSchool) return false
    return true
  }

  winnerClassroom () {
    const classFilter = this.currentFilters.filter((filter) => filter.name === 'Class')

    if (classFilter.length > 0) return classFilter[0].option === 'All' ? this.user.classrooms[0] : classFilter[0].option
    if (this.user.classrooms) return this.user.classrooms[0]
  }

  contextualHeader () {
    return this.currentFilters.some((filter) => filter.name === 'Schools') ? 'School' : 'Class'
  }

  render () {
    if (this.loading) {
      this.element.innerHTML = '<div class="loader">Loading...</div>'
      return
    }

    this.element.innerHTML = `
      <div>
        <div class="row">
          <div class="d-none d-md-block col">
            <h1>${this.escape(this.name)}</h1>
          </div>
          <div class="col">
            ${this.renderClassroomWinner()}
          </div>
        </div>
        ${this.renderLiveToggle()}
        <div class="form-row align-items-center d-flex justify-content-around row">
          ${this.renderFilters()}
          ${this.renderShowAllToggle()}
          ${this.renderAllTimeToggle()}
        </div>
        <div class="row">
          <table id="leaderboardTable" class="table">
            <thead>
              <tr>
                <th>#</th>
                <th></th>
                <th>Name</th>
                <th></th>
                <th class="d-none d-lg-block">${this.contextualHeader()}</th>
                <th>Score</th>
              </tr>
            </thead>
            <tbody>
              ${this.sortedLeaderboard().map((entry) => this.renderEntry(entry)).join('')}
            </tbody>
          </table>
        </div>
        ${this.connected ? '<span id="connected"></span>' : ''}
      </div>
    `
  }

  renderLiveToggle () {
    if (this.user.role !== 'employee' && this.user.role !== 'school_admin') return ''

    return `
      <div class="row">
        <div class="col">
          <div id="toggleLive" class="custom-control custom-switch form-group">
            <input type="checkbox" class="custom-control-input" id="liveSwitch" ${this.live ? 'checked' : ''} data-action="live-leaderboard#toggleLive">
            <label class="custom-control-label" for="liveSwitch">Live Leaderboard</label>
          </div>
        </div>
      </div>
    `
  }

  renderFilters () {
    return Object.keys(this.filters).map((key) => this.renderFilter(this.filters[key])).join('')
  }

  renderFilter (filter) {
    const selectedFilter = this.currentFilters.filter((currentFilter) => currentFilter.name === filter.name)[0]
    const selected = selectedFilter ? selectedFilter.option : filter.default
    const dropdownId = `${filter.name.replace(' ', '-')}-dropdown`

    return `
      <div class="col-6">
        <div class="form-group">
          <div id="${dropdownId}" class="dropdown filter">
            <button class="btn btn-secondary dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
              ${this.escape(selected)}
            </button>
            <div class="dropdown-menu">
              ${filter.options.map((option) => this.renderFilterOption(filter.name, option)).join('')}
            </div>
          </div>
        </div>
      </div>
    `
  }

  renderFilterOption (name, option) {
    const id = `${name}-${option.replace(' ', '-')}`
    return `
      <button type="button" id="${this.escapeAttribute(id)}" class="dropdown-item" data-filter-name="${this.escapeAttribute(name)}" data-filter-option="${this.escapeAttribute(option)}" data-action="live-leaderboard#selectFilter">
        ${this.escape(option)}
      </button>
    `
  }

  renderShowAllToggle () {
    if (this.live) return ''

    return `
      <div class="col">
        <div id="showAll" class="custom-control custom-switch form-group">
          <input type="checkbox" class="custom-control-input" id="showAllSwitch" ${this.showAll ? 'checked' : ''} data-action="live-leaderboard#toggleShowAll">
          <label class="custom-control-label" for="showAllSwitch">Show all</label>
        </div>
      </div>
    `
  }

  renderAllTimeToggle () {
    if (this.live) return ''

    return `
      <div class="col-sm col">
        <div id="allTime" class="custom-control custom-switch form-group">
          <input type="checkbox" class="custom-control-input" id="allTimeSwitch" ${this.allTime ? 'checked' : ''} data-action="live-leaderboard#toggleAllTime">
          <label class="custom-control-label" for="allTimeSwitch">All Time</label>
        </div>
      </div>
    `
  }

  renderClassroomWinner () {
    const classroom = this.winnerClassroom()
    if (!classroom) return ''

    const winner = this.winners.filter((winner) => winner[0] === classroom)
    const winnerText = winner.map((winner) => `${winner[1]} - ${winner[2]} points`).join(', ')

    return `
      <div>
        <p><b class="font-weight-bold">${this.escape(classroom)} winner: </b>${this.escape(winnerText)}</p>
      </div>
    `
  }

  renderEntry (entry) {
    const classNames = []
    if (entry.lastChanged) classNames.push('score-changed')
    if (this.user.id === entry.id) {
      classNames.push('font-weight-bold')
      classNames.push('current-user')
    }

    return `
      <tr id="row-${entry.id}" class="${classNames.join(' ')}">
        <td id="pos-${entry.id}">${entry.position}</td>
        <td id="icon-${entry.id}">${this.renderIcon(entry.icon)}</td>
        <td id="name-${entry.id}">${this.escape(entry.name)}</td>
        <td id="awards-${entry.id}">${this.renderAwards(entry.awards)}</td>
        ${this.renderContextualRow(entry)}
        <td id="score-${entry.id}">${this.escape(String(entry.score))}</td>
      </tr>
    `
  }

  renderContextualRow (entry) {
    if (this.currentFilters.some((filter) => filter.name === 'Schools')) {
      return `<td class="d-none d-lg-block" id="${entry.id}schools-">${this.escape(entry.school_name)}</td>`
    }

    const classroomNames = entry.classroom_names && entry.classroom_names.length > 0 ? entry.classroom_names.join(', ') : ''
    return `<td class="d-none d-lg-block" id="${entry.id}classrooms-">${this.escape(classroomNames)}</td>`
  }

  renderIcon (icon) {
    if (!icon) return ''

    const iconArray = icon.split(',')
    return `<i class="fas fa-${this.escapeAttribute(iconArray[1])}" style="color: ${this.escapeAttribute(iconArray[0])}"></i>`
  }

  renderAwards (awards) {
    let numAwards = awards
    let stars = ''

    while (numAwards >= 5) {
      stars += '<i class="fas fa-star" style="color: gold" title="Five wins!" data-toggle="tooltip"></i>'
      numAwards -= 5
    }

    while (numAwards >= 3) {
      stars += '<i class="fas fa-star" style="color: silver" title="Three wins!" data-toggle="tooltip"></i>'
      numAwards -= 3
    }

    while (numAwards >= 1) {
      stars += '<i class="fas fa-star" style="color: red" title="Came top of the leaderboard once!" data-toggle="tooltip"></i>'
      numAwards -= 1
    }

    return stars
  }

  escape (value) {
    return String(value || '').replace(/[&<>"']/g, (character) => {
      return {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
      }[character]
    })
  }

  escapeAttribute (value) {
    return this.escape(value).replace(/`/g, '&#96;')
  }
}
