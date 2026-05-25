import { EventEmitter } from "events";

import dispatcher from "../dispatcher";
import consumer from "../channels/consumer";

class LiveLeaderboardStore extends EventEmitter {
  constructor() {
    super();
    this.loading = true;
    this.initialLeaderboard = {};
    this.weeklyLeaderboard = {};
    this.allTimeLeaderboard = {};
    this.lastChanged = "";
    this.awards = {};
    this.name = "";
    this.currentFilters = [];
    this.filters = [];
    this.schools = {};
    this.classrooms = {};
    this.user = {};
    this.allTime = false;
    this.allSchoolsLoaded = false;
    this.allSchools = false;
    this.showAll = false;
    this.live = false;
    this.winners = [];
    this.schoolGroup = false;
    this.connected = false;
    this.subject = $(".jsVars[data-subject-name]").attr("data-subject-name");
    this.school = $(".jsVars[data-school-name]").attr("data-school-name");
    this.school_group = $(".jsVars[data-school_group-name]").attr(
      "data-school_group-name",
    );
    this.topic = $(".jsVars[data-topic-id]").attr("data-topic-id");
  }

  listenToLeaderboard() {
    const lb = this;
    consumer.subscriptions.create(
      {
        channel: "LeaderboardChannel",
        subject: this.subject,
        school: this.school,
        school_group: this.school_group,
      },
      {
        connected() {
          lb.connected = true;
          lb.emit("change");
        },
        // Called when the subscription is ready for use on the server

        disconnected() {},
        // Called when the subscription has been terminated by the server

        received(data) {
          // If this isn't for the topic being shown, return and do nothing
          if (this.topic === undefined) {
            lb.leaderboardChange(data, "ALL");
          } else if (data.topic === this.topic) {
            lb.leaderboardChange(data, "TOPIC");
          }
        },
      },
    );
  }

  loadLeaderboard() {
    this.listenToLeaderboard();

    let path = window.location.pathname + ".json?";

    if (this.topic) {
      path += `&topic=${this.topic}`;
    }
    if (this.schoolGroup) {
      path += "&school_group=true";
    }
    if (this.allTime) {
      path += "&all_time=true";
    }

    $.ajax({
      type: "GET",
      url: path,
      success: (result) => {
        this.processLeaderboardLoad(result);
        this.processScores();
        this.processFilterLoad(result);
        this.emit("change");
      },
      error: (error) => console.log(error),
    });
  }

  processLeaderboardLoad(result) {
    const leaderboard = {};
    for (const userData of result.leaderboard) {
      leaderboard[userData.id] = { ...userData };
    }

    if (this.allTime) {
      this.allTimeLeaderboard = leaderboard;
    } else {
      this.weeklyLeaderboard = leaderboard;
      this.initialLeaderboard = this.weeklyLeaderboard;
    }

    this.awards = result.awards;
    this.name = result.name;
    this.user = result.user;
    this.winners = result.winners;
  }

  processScores() {
    if (this.allTime) {
      for (const entry in this.allTimeLeaderboard) {
        this.calculateAllTimeScore(entry);
      }
    } else if (!this.live) {
      // Deep copy of the leaderboard
      this.currentLeaderboard = JSON.parse(
        JSON.stringify(this.weeklyLeaderboard),
      );
    }
  }

  calculateAllTimeScore(id) {
    if (this.currentLeaderboard[id]) {
      const weeklyScore = parseInt(this.weeklyLeaderboard[id].score);
      const allTime = parseInt(this.allTimeLeaderboard[id].score);
      this.currentLeaderboard[id].score = weeklyScore + allTime;
    } else {
      this.currentLeaderboard[id] = this.allTimeLeaderboard[id];
    }
  }

  processFilterLoad(result) {
    this.schools = result.schools;
    this.classrooms = result.classrooms;

    const schoolArray = [];
    const classroomArray = [];

    classroomArray.push("All");
    this.classrooms.map((classroom) => {
      classroomArray.push(classroom);
    });

    this.filters["classroom"] = {
      name: "Class",
      options: classroomArray,
      default: "Select Class",
    };

    if (this.schools.length > 1) {
      schoolArray.push("All");
      this.schools.map((school) => {
        schoolArray.push(school);
      });

      this.filters["schools"] = {
        name: "Schools",
        options: schoolArray,
        default: "Select School",
      };
    }
  }

  getLoading() {
    return this.loading;
  }

  getCurrentLeaderboard() {
    return this.currentLeaderboard;
  }

  getUser() {
    return this.user;
  }

  getFilters() {
    return this.filters;
  }

  getCurrentFilters() {
    return this.currentFilters;
  }

  getPath() {
    return this.path;
  }

  getShowAll() {
    return this.showAll;
  }

  getLive() {
    return this.live;
  }

  getAllTime() {
    return this.allTime;
  }

  getAwards() {
    return this.awards;
  }

  getName() {
    return this.name;
  }

  getWinners() {
    return this.winners;
  }

  getConnected() {
    return this.connected;
  }

  leaderboardFilterChange(value) {
    // Remove any existing filters with the same name from the array
    this.currentFilters = this.currentFilters.filter((filter) => {
      if (filter.name !== value.name) {
        return true;
      } else return false;
    });

    this.currentFilters.push(value);

    if (value.name === "Schools") {
      this.schoolGroup = true;
      this.currentFilters = this.currentFilters.filter((filter) => {
        return filter.name === "Schools";
      });
      if (!this.allSchoolsLoaded) {
        this.loadLeaderboard(true);
        this.allSchoolsLoaded = true;
      }

      this.allSchools = !this.allSchools;
    }

    if (value.name === "Class") {
      this.currentFilters = this.currentFilters.filter(
        (filter) => filter.name === "Class",
      );
    }

    // Push this new filter onto the array

    this.emit("change");
  }

  leaderboardChange(data) {
    const { id } = data;

    this.loading = false;
    if (this.weeklyLeaderboard === undefined) {
      setTimeout(() => {
        this.leaderboardChange(data);
      }, 1000);
    }

    let score = data.subject_score;

    if (this.live && this.initialLeaderboard[id]) {
      score = score - this.initialLeaderboard[id].score;
    }

    // Get all the user details from the change object, but replace the score with the "live score"
    this.currentLeaderboard[id] = {
      ...this.currentLeaderboard[id],
      ...data,
      score: score,
    };

    this.lastChanged = id;
    this.currentLeaderboard[id].lastChanged = true;

    this.emit("change");

    // After a second, remove the lastChanged flag.  This allows users who score twice in a
    // row to flash twice.
    setTimeout(() => {
      if (this.currentLeaderboard[this.lastChanged] !== undefined) {
        this.currentLeaderboard[this.lastChanged].lastChanged = false;
        this.emit("change");
      }
    }, 1000);
  }

  toggleLiveLeaderboard() {
    this.live = !this.live;
    if (this.live) {
      this.showAll = true;
      this.allTime = false;
      if (this.schools.length > 1) {
        this.leaderboardFilterChange({ name: "Schools", option: "All" });
      } else {
        this.initialLeaderboard = this.weeklyLeaderboard;
      }
      this.currentLeaderboard = {};
    } else {
      this.processScores();
    }
  }

  handleActions(action) {
    switch (action.type) {
      case "LEADERBOARD_LOAD": {
        this.loadLeaderboard(action.value);
        break;
      }
      case "LEADERBOARD_RESET": {
        this.resetLeaderboard(action.value);
        break;
      }
      case "LEADERBOARD_ALL_TIME_TOGGLE": {
        this.allTime = !this.allTime;
        if (Object.entries(this.allTimeLeaderboard).length === 0) {
          this.loadLeaderboard();
          this.processScores();
        } else {
          this.processScores();
        }
        this.emit("change");
        break;
      }
      case "LEADERBOARD_SHOW_ALL_TOGGLE": {
        this.showAll = !this.showAll;
        this.emit("change");
        break;
      }
      case "LEADERBOARD_LIVE_TOGGLE": {
        this.toggleLiveLeaderboard();
        this.emit("change");
        break;
      }
      case "FILTER_CHANGE": {
        this.leaderboardFilterChange(action.value);
        break;
      }

      default:
    }
  }
}

const liveLeaderboardStore = new LiveLeaderboardStore();
dispatcher.register(
  liveLeaderboardStore.handleActions.bind(liveLeaderboardStore),
);
export default liveLeaderboardStore;
