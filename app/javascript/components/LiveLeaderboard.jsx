import React from 'react'
import { Table, Row, Button, FormGroup } from 'reactstrap'
import { compose } from 'recompose'

import LiveLeaderboardStore from '../stores/LiveLeaderboardStore'
import * as LiveLeaderboardActions from '../actions/LiveLeaderboardActions'
import Entry from './live_leaderboard/Entry'
import Filters from './live_leaderboard/Filters'
import withLoading from '../hoc/withLoading'

function ResetButton (props) {
  return (<Button id='reset-button' {...props}>Reset</Button>)
}

const ResetButtonWithLoading = withLoading(ResetButton)

class LiveLeaderboard extends React.Component {
  constructor () {
    super()
    this.state = {
      leaderboard: LiveLeaderboardStore.getCurrentLeaderboard(),
      loading: LiveLeaderboardStore.getLoading(),
      filters: LiveLeaderboardStore.getFilters(),
      currentFilters: LiveLeaderboardStore.getCurrentFilters()
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
      currentFilters: LiveLeaderboardStore.getCurrentFilters()
    })
  }

  resetLeaderboard () {
    LiveLeaderboardActions.resetLeaderboard()
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
    return sortedLeaderboard
  }

  checkFilters (entry) {
    const filters = this.state.currentFilters
    for (let i in filters) {
      let filter = filters[i]
      if (filter.name === 'Schools' && filter.option !== 'All' && entry.school_name !== filter.option) return false
      if ((filter.name === 'Class' && filter.option !== 'All') && !entry.classroom_names.includes(filter.option)) return false
    }
    return true
  }

  render () {
    const leaderboard = this.sortLeaderboard()
    const { loading, filters, currentFilters } = this.state

    // Map every entry in the current leaderboard array into an entry component
    const Entries = leaderboard.map((entry) => {
      return <Entry key={entry.id} {...entry} />
    })

    return (
      <div>
        <Row className='page-header'>
          <h1>Leaderboard</h1>
        </Row>
        <Row className='form-row align-items-center d-flex justify-content-around'>
          {<Filters filters={filters} currentFilters={currentFilters}/>}
          <FormGroup>
            <ResetButton onClick={() => this.resetLeaderboard()} />
          </FormGroup>
        </Row>
        <Row>
          <Table>
            <thead>
              <tr>
                <th>#</th>
                <th>Name</th>
                <th>Classes</th>
                <th>Score</th>
              </tr>
            </thead>
            <tbody>
              {Entries}
            </tbody>
          </Table>
        </Row>
      </div>
    )
  }
}

export default compose(
  withLoading
)(LiveLeaderboard)
