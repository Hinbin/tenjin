import { EventEmitter } from 'events'

import dispatcher from '../dispatcher'

class LiveLeaderboardStore extends EventEmitter {
  constructor () {
    super()
    this.loading = true
    this.initialLeaderboard = {}
    this.currentLeaderboard = {}
    this.lastChanged = ''
    this.awards = {}
    this.leaderboardParams = {}
    this.currentFilters = []
    this.filters = []
    this.schools = {}
    this.classrooms = {}
  }

  listenToLeaderboard () {
    let lb = this
    App.cable.subscriptions.create({
      channel: 'LeaderboardChannel',
      subject: window.gon.subject,
      school: window.gon.school,
      school_group: window.gon.school_group
    }, {
      connected () {

      },
      // Called when the subscription is ready for use on the server

      disconnected () { },
      // Called when the subscription has been terminated by the server

      received (data) {
        // If this isn't for the topic being shown, return and do nothing
        if (window.gon.topic === undefined) {
          lb.leaderboardChange(data, 'ALL')
        } else if (data.topic === window.gon.topic) {
          lb.leaderboardChange(data, 'TOPIC')
        }
      }
    })
  }

  loadLeaderboard () {
    this.listenToLeaderboard()

    const path = window.gon.path + '.json?'

    $.ajax({
      type: 'GET',
      url: path,
      success: (result) => {
        this.processLeaderboardLoad(result)
        this.processFilterLoad(result)
        this.emit('change')
      },
      error: (error) => this.processError(error)
    })
  }

  processLeaderboardLoad (result) {
    // Save the current leaderboard into local storage for retrival later
    let leaderboard = {}
    for (let userData of result.leaderboard) {
      leaderboard[userData.id] = { ...userData }
    }

    this.currentLeaderboard = leaderboard
    this.awards = result.awards
    this.leaderboardParams = result.params
  }

  processFilterLoad (result) {
    this.schools = result.schools
    this.classrooms = result.classrooms

    let schoolArray = []
    let classroomArray = []

    classroomArray.push('All')
    this.classrooms.map((classroom) => { classroomArray.push(classroom) })

    this.filters['classroom'] = {
      name: 'Class',
      options: classroomArray,
      default: 'Select Class'
    }

    if (this.schools.length > 1) {
      schoolArray.push('All')
      this.schools.map((school) => { schoolArray.push(school) })

      this.filters['schools'] = {
        name: 'Schools',
        options: schoolArray,
        default: 'Select School'
      }
    }
  }

  loadInitialScores () {
    let initialLeaderboard = JSON.parse(localStorage.getItem('leaderboard'))

    if (initialLeaderboard === null) {
      return this.resetLeaderboard()
    } else {
      this.initialLeaderboard = initialLeaderboard
      return Promise.resolve()
    }
  }

  getLoading () {
    return this.loading
  }

  getCurrentLeaderboard () {
    return this.currentLeaderboard
  }

  getFilters () {
    return this.filters
  }

  getCurrentFilters () {
    return this.currentFilters
  }
  getPath () {
    return this.path
  }

  leaderboardFilterChange (value) {
    // Remove any existing filters with the same name from the array
    this.currentFilters = this.currentFilters.filter((filter) => {
      if (filter.name !== value.name) {
        return true
      } else return false
    })

    this.currentFilters.push(value)

    if (value.name === 'Schools') {
      this.currentFIlters = this.currentFilters.filter((filter) => filter.name === 'Class')
    }

    if (value.name === 'Classrooms') {
      this.currentFIlters = this.currentFilters.filter((filter) => filter.name === 'Schools')
    }

    // Push this new filter onto the array

    this.emit('change')
  }

  removeEntry (snapshot) {
    const id = snapshot.key
    delete this.currentLeaderboard[id]
    this.emit('change')
  }

  leaderboardChange (data, all) {
    const { id } = data

    this.loading = false
    if (this.initialLeaderboard === undefined) {
      setTimeout(() => { this.leaderboardChange(data) }, 1000)
    }

    // Get all the user details from the change object, but replace the score with the "live score"
    this.currentLeaderboard[id] = { ...data, score: data.subject_score }

    this.lastChanged = id
    this.currentLeaderboard[id].lastChanged = true

    this.emit('change')

    // After a second, remove the lastChanged flag.  This allows users who score twice in a
    // row to flash twice.
    setTimeout(() => {
      if (this.currentLeaderboard[this.lastChanged] !== undefined) {
        this.currentLeaderboard[this.lastChanged].lastChanged = false
        this.emit('change')
      }
    }, 1000)
  }

  calculateLiveScore (leaderboardChange) {
    const { score } = leaderboardChange
    return score

    // Calculate the difference between the score when the leaderboard was loaded, and the score given
    // in the change
    /*
    try {
      const initialScore = this.initialLeaderboard[path[0]][path[1]][uid]
      if (initialScore === undefined) {
        return score
      } else {
        const liveScore = score - initialScore
        return liveScore
      }
    } catch (TypeError) {
      return 0
    */
  }

  resetLeaderboard () {

  }

  handleActions (action) {
    switch (action.type) {
      case 'LEADERBOARD_LOAD': {
        this.loadLeaderboard(action.value)
        break
      }
      case 'LEADERBOARD_RESET': {
        this.resetLeaderboard(action.value)
        break
      }
      case 'FILTER_CHANGE':
      {
        this.leaderboardFilterChange(action.value)
        break
      }

      default:
    }
  }
}

const liveLeaderboardStore = new LiveLeaderboardStore()
dispatcher.register(liveLeaderboardStore.handleActions.bind(liveLeaderboardStore))
export default liveLeaderboardStore
