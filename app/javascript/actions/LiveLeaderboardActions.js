import dispatcher from "../dispatcher";

export function loadLeaderboard() {
  dispatcher.dispatch({
    type: "LEADERBOARD_LOAD",
  });
}

export function toggleLiveLeaderboard() {
  dispatcher.dispatch({
    type: "LEADERBOARD_LIVE_TOGGLE",
  });
}

export function toggleShowAll() {
  dispatcher.dispatch({
    type: "LEADERBOARD_SHOW_ALL_TOGGLE",
  });
}

export function toggleAllTime() {
  dispatcher.dispatch({
    type: "LEADERBOARD_ALL_TIME_TOGGLE",
  });
}

export function setFilter(name, option) {
  dispatcher.dispatch({
    type: "FILTER_CHANGE",
    value: {
      name: name,
      option: option,
    },
  });
}
