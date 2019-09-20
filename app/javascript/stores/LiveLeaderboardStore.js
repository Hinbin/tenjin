import { EventEmitter } from 'events'

import dispatcher from '../dispatcher'

class LiveLeaderboardStore extends EventEmitter {
  constructor () {
    super()
    this.loading = true
    this.initialLeaderboard = {}
    this.currentLeaderboard = {}
    this.lastChanged = ''
    this.oldPath = []
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

  loadInitialScores () {
    let initialLeaderboard = JSON.parse(localStorage.getItem('leaderboard'))

    if (initialLeaderboard === null) {
      return this.resetLeaderboard()
    } else {
      this.initialLeaderboard = initialLeaderboard
      return Promise.resolve()
    }
  }

  loadLeaderboard () {
    this.listenToLeaderboard()

    const path = window.gon.path + '.json?'

    $.ajax({
      type: 'GET',
      url: path,
      success: (result) => {
        // Save the current leaderboard into local storage for retrival later     
        let leaderboard = {}
        for (let userData of result.leaderboard) {
          leaderboard[userData.id] = { ...userData }
        }

        this.currentLeaderboard = leaderboard
        this.emit('change')
      },
      error: (error) => this.processError(error)
    })
  }

  getLoading () {
    return this.loading
  }

  getCurrentLeaderboard () {
    return this.currentLeaderboard
  }

  getPath () {
    return this.path
  }

  leaderboardFilterChange (value) {
    const oldPath = this.path
    let newPath
    if (value.name === 'Subjects') {
      newPath = [value.option, 'Overall']
    } else if (value.name === 'Topics') {
      newPath = [oldPath[0], value.option]
    }

    let paths = {
      oldPath: oldPath,
      path: newPath
    }

    if (value.name !== 'Schools') this.loadLeaderboard(paths).then(() => this.emit('change'))
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
