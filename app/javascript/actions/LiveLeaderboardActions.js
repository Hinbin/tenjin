import dispatcher from '../dispatcher'

export function loadLeaderboard () {
  dispatcher.dispatch({
    type: 'LEADERBOARD_LOAD'
  })
}

export function resetLeaderboard () {
  dispatcher.dispatch({
    type: 'LEADERBOARD_RESET'
  })
}

export function setFilter (name, option) {
  dispatcher.dispatch({
    type: 'FILTER_CHANGE',
    value: {
      name: name,
      option: option }
  })
}