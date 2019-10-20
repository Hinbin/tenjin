import React from 'react'
import { Table, Row, Button, FormGroup, Input, Label, Col } from 'reactstrap'
import { compose } from 'recompose'

import LiveLeaderboardStore from '../stores/LiveLeaderboardStore'
import * as LiveLeaderboardActions from '../actions/LiveLeaderboardActions'
import Entry from './live_leaderboard/Entry'
import Filters from './live_leaderboard/Filters'
import ClassroomWinner from './live_leaderboard/ClassroomWinner'
import withLoading from '../hoc/withLoading'

class LiveLeaderboard extends React.Component {
  constructor () {
    super()
    this.state = {
      leaderboard: LiveLeaderboardStore.getCurrentLeaderboard(),
      loading: LiveLeaderboardStore.getLoading(),
      filters: LiveLeaderboardStore.getFilters(),
      currentFilters: LiveLeaderboardStore.getCurrentFilters(),
      user: LiveLeaderboardStore.getUser(),
      showAll: LiveLeaderboardStore.getShowAll(),
      allTime: LiveLeaderboardStore.getAllTime(),
      live: LiveLeaderboardStore.getLive(),
      name: LiveLeaderboardStore.getName(),
      winners: LiveLeaderboardStore.getWinners(),
      connected: LiveLeaderboardStore.getConnected()
    }
    this.getLeaderboard = this.getLeaderboard.bind(this)

    LiveLeaderboardActions.loadLeaderboard()
    LiveLeaderboardStore.on('change', this.getLeaderboard)
  }

  componentWillUnmount () {
    LiveLeaderboardStore.removeListener('change', this.getLeaderboard)
  }

  getLeaderboard () {
    this.setState({
      leaderboard: LiveLeaderboardStore.getCurrentLeaderboard(),
      loading: LiveLeaderboardStore.getLoading(),
      filters: LiveLeaderboardStore.getFilters(),
      currentFilters: LiveLeaderboardStore.getCurrentFilters(),
      user: LiveLeaderboardStore.getUser(),
      showAll: LiveLeaderboardStore.getShowAll(),
      allTime: LiveLeaderboardStore.getAllTime(),
      live: LiveLeaderboardStore.getLive(),
      name: LiveLeaderboardStore.getName(),
      winners: LiveLeaderboardStore.getWinners(),
      connected: LiveLeaderboardStore.getConnected()
    })
  }

  toggleLiveLeaderboard () {
    LiveLeaderboardActions.toggleLiveLeaderboard()
  }

  toggleShowAll () {
    LiveLeaderboardActions.toggleShowAll()
  }

  toggleAllTime () {
    LiveLeaderboardActions.toggleAllTime()
  }

  // Converts the leaderboard object into a sorted array, sorted by score.
  sortLeaderboard () {
    // Build the array to be sorted that will contain all the leaderboard information
    let sortedLeaderboard = []
    const leaderboard = this.state.leaderboard

    for (var key in leaderboard) {
      if (leaderboard.hasOwnProperty(key)) {
        if (this.checkFilters(leaderboard[key])) {
          sortedLeaderboard.push(leaderboard[key])
        }
      }
    }

    sortedLeaderboard.sort((a, b) => b.score - a.score)

    for (var i in sortedLeaderboard) {
      sortedLeaderboard[i].position = parseInt(i, 10) + 1
    }
    if (!this.state.showAll) {
      sortedLeaderboard = this.snipTableData(sortedLeaderboard)
    }
    return sortedLeaderboard
  }

  snipTableData (tableData) {
    const tableSize = tableData.length
    const maxUsersToDisplay = 10
    let userRowIndex = tableData.findIndex(x => x.id === this.state.user.id)

    if (tableSize < (maxUsersToDisplay - 1)) {
      // If there aren't enough users to fill the table, show the whole table
      return tableData
    } else if (userRowIndex < maxUsersToDisplay) {
      // If the user is close enough to the top of the table, display the top only
      return tableData.slice(0, (maxUsersToDisplay))
      // Otherwise snip the 5 around the user
    } else if ((userRowIndex + (maxUsersToDisplay / 2)) > tableSize) {
      // If the user is too close to the bottom - display from the bottom of the table up
      return tableData.slice(tableSize - maxUsersToDisplay)
    } else {
      let lower = Math.max(0, userRowIndex - (maxUsersToDisplay / 2) + 1)
      let upper = Math.min(tableSize, lower + maxUsersToDisplay)
      return tableData.slice(lower, upper)
    }
  }

  checkFilters (entry) {
    const filters = this.state.currentFilters
    const userSchool = this.state.user.school
    let schoolFilterSet = false

    for (let i in filters) {
      let filter = filters[i]
      if (filter.name === 'Schools' && filter.option !== 'All' &&
          entry.school_name !== filter.option) return false
      if ((filter.name === 'Class' && filter.option !== 'All') &&
          ((entry.classroom_names === null ||
          !entry.classroom_names.includes(filter.option)) ||
          entry.school_name !== userSchool)) return false
      if (filter.name === 'Schools') { schoolFilterSet = true }
    }
    // If no schools have been set, only show user's school
    if ((!schoolFilterSet) && entry.school_name !== userSchool) { return false }
    return true
  }

  render () {
    const leaderboard = this.sortLeaderboard()
    const { loading, filters, currentFilters, user, showAll, allTime, live, name, winners, connected } = this.state
    const classFilter = currentFilters.filter((f) => { return f.name === 'Class' })

    let winnerClassroom

    if (classFilter.length > 0) {
      winnerClassroom = classFilter[0].option === 'All' ? user.classrooms[0] : classFilter[0].option
    } else if (user.classrooms) {
      winnerClassroom = user.classrooms[0]
    }

    // Map every entry in the current leaderboard array into an entry component
    const Entries = leaderboard.map((entry) => {
      return <Entry key={entry.id} currentFilters={currentFilters} user={user} {...entry} />
    })

    const checkSchoolFilter = this.state.currentFilters.filter((f) => { return f.name === 'Schools' })

    let contextualHeader = ''

    if (checkSchoolFilter.length > 0) {
      contextualHeader = 'School'
    } else {
      contextualHeader = 'Class'
    }

    return (
      <div>
        <Row>
          <Col className='d-none d-md-block'>
            <h1>{name}</h1>
          </Col>
          <Col>
            <ClassroomWinner classroom={winnerClassroom} winners={winners}/>
          </Col>
        </Row>

        {(user.role === 'employee' || user.role === 'school_admin') &&
          <Row>
            <Col>
              <FormGroup id='toggleLive' className='custom-control custom-switch'>
                <Input
                  type='checkbox'
                  className='custom-control-input'
                  id='liveSwitch'
                  checked={live}
                  onChange={() => this.toggleLiveLeaderboard()}/>
                <Label className='custom-control-label' for='liveSwitch'>Live Leaderboard</Label>
              </FormGroup>
            </Col>
          </Row>
        }

        <Row className='form-row align-items-center d-flex justify-content-around'>
          {<Filters filters={filters} currentFilters={currentFilters}/>}
          {!live &&
          <Col>
            <FormGroup className='custom-control custom-switch' id='showAll'>
              <Input
                type='checkbox'
                className='custom-control-input'
                id='showAllSwitch'
                checked={showAll}
                onChange={() => this.toggleShowAll()}/>
              <Label className='custom-control-label' for='showAllSwitch'>Show all</Label>
            </FormGroup>
          </Col>
          }
          {!live &&
          <Col className='col-sm'>
            <FormGroup className='custom-control custom-switch' id='allTime'>
              <Input
                type='checkbox'
                className='custom-control-input'
                id='allTimeSwitch'
                checked={allTime}
                onChange={() => this.toggleAllTime()}/>
              <Label className='custom-control-label' for='allTimeSwitch'>All Time</Label>
            </FormGroup>
          </Col>
          }
        </Row>
        <Row>
          <Table id='leaderboardTable'>
            <thead>
              <tr>
                <th>#</th>
                <th/>
                <th>Name</th>
                <th/>
                <th className='d-none d-lg-block'>{contextualHeader}</th>
                <th>Score</th>
              </tr>
            </thead>
            <tbody>
              {Entries}
            </tbody>
          </Table>
        </Row>
        {connected &&
        <span id='connected'/>
        }
      </div>
    )
  }
}

export default compose(
  withLoading
)(LiveLeaderboard)
