import Alpine from "alpinejs";

import consumer from "../channels/consumer";

const MAX_USERS_TO_DISPLAY = 10;

function escapeHtml(value) {
  if (value == null) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

Alpine.data(
  "liveLeaderboard",
  ({
    subjectName,
    schoolName,
    schoolGroupName,
    topicId,
    canSeeLiveToggle,
  }) => ({
    // ── from x-data args ──
    subjectName,
    schoolName,
    schoolGroupName,
    topicId,
    canSeeLiveToggle,

    // ── populated by load ──
    loading: true,
    name: "",
    user: {},
    schools: [],
    classrooms: [],
    winners: [],

    // ── leaderboard data ──
    weeklyLeaderboard: {},
    allTimeLeaderboard: {},
    initialLeaderboard: {},
    currentLeaderboard: {},

    // ── UI toggles ──
    live: false,
    showAll: false,
    allTime: false,

    // ── filters ──
    currentFilters: [],
    allSchoolsLoaded: false,

    // ── connection state ──
    connected: false,
    subscription: null,

    // ── lifecycle ──
    init() {
      this.listenToLeaderboard();
      this.loadLeaderboard();
    },

    destroy() {
      this.subscription?.unsubscribe();
    },

    // ── data ──
    async loadLeaderboard({ allTime = false, schoolGroup = false } = {}) {
      const params = new URLSearchParams();
      if (this.topicId != null) params.set("topic", this.topicId);
      if (schoolGroup) params.set("school_group", "true");
      if (allTime) params.set("all_time", "true");

      const url = `${window.location.pathname}.json?${params.toString()}`;

      try {
        const response = await fetch(url, {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        });
        if (!response.ok) {
          console.error(`Leaderboard load failed: ${response.status}`);
          return;
        }
        const result = await response.json();
        this._applyLoadResult(result, { allTime });
        this.loading = false;
      } catch (e) {
        console.error(e);
      }
    },

    _applyLoadResult(result, { allTime }) {
      const lb = {};
      for (const entry of result.leaderboard) lb[entry.id] = { ...entry };

      if (allTime) {
        this.allTimeLeaderboard = lb;
      } else {
        this.weeklyLeaderboard = lb;
        this.initialLeaderboard = lb;
      }

      this.name = result.name;
      this.user = result.user;
      this.winners = result.winners;
      this.schools = result.schools;
      this.classrooms = result.classrooms;

      this.processScores();
    },

    processScores() {
      if (this.allTime) {
        const merged = {};
        const ids = new Set([
          ...Object.keys(this.weeklyLeaderboard),
          ...Object.keys(this.allTimeLeaderboard),
        ]);
        for (const id of ids) {
          const weekly = this.weeklyLeaderboard[id];
          const allTimeEntry = this.allTimeLeaderboard[id];
          if (weekly && allTimeEntry) {
            merged[id] = {
              ...weekly,
              score: parseInt(weekly.score) + parseInt(allTimeEntry.score),
            };
          } else {
            merged[id] = { ...(allTimeEntry ?? weekly) };
          }
        }
        this.currentLeaderboard = merged;
      } else if (!this.live) {
        this.currentLeaderboard = JSON.parse(
          JSON.stringify(this.weeklyLeaderboard),
        );
      }
    },

    // ── ActionCable ──
    listenToLeaderboard() {
      this.subscription = consumer.subscriptions.create(
        {
          channel: "LeaderboardChannel",
          subject: this.subjectName,
          school: this.schoolName,
          school_group: this.schoolGroupName,
        },
        {
          connected: () => {
            this.connected = true;
          },
          disconnected: () => {
            this.connected = false;
          },
          received: (data) => {
            if (this.topicId == null || data.topic === this.topicId) {
              this.leaderboardChange(data);
            }
          },
        },
      );
    },

    leaderboardChange(data) {
      if (Object.keys(this.weeklyLeaderboard).length === 0 && !this.live) {
        setTimeout(() => this.leaderboardChange(data), 1000);
        return;
      }

      const { id } = data;
      let score = data.subject_score;
      if (this.live && this.initialLeaderboard[id]) {
        score = score - this.initialLeaderboard[id].score;
      }

      this.currentLeaderboard[id] = {
        ...this.currentLeaderboard[id],
        ...data,
        score,
        lastChanged: true,
      };

      setTimeout(() => {
        if (this.currentLeaderboard[id]) {
          this.currentLeaderboard[id] = {
            ...this.currentLeaderboard[id],
            lastChanged: false,
          };
        }
      }, 1000);
    },

    // ── filters / toggles ──
    setFilter(name, option) {
      this.currentFilters = this.currentFilters.filter((f) => f.name !== name);
      this.currentFilters.push({ name, option });

      if (name === "Schools") {
        this.currentFilters = this.currentFilters.filter(
          (f) => f.name === "Schools",
        );
        if (!this.allSchoolsLoaded) {
          this.loadLeaderboard({ schoolGroup: true });
          this.allSchoolsLoaded = true;
        }
      }

      if (name === "Class") {
        this.currentFilters = this.currentFilters.filter(
          (f) => f.name === "Class",
        );
      }
    },

    toggleLive() {
      if (this.live) {
        // turning on
        this.showAll = true;
        this.allTime = false;
        this.currentLeaderboard = {};
        if (this.schools.length > 1) {
          this.setFilter("Schools", "All");
        } else {
          this.initialLeaderboard = this.weeklyLeaderboard;
        }
      } else {
        this.processScores();
      }
    },

    onAllTimeToggle() {
      if (this.allTime && Object.keys(this.allTimeLeaderboard).length === 0) {
        this.loadLeaderboard({ allTime: true });
      } else {
        this.processScores();
      }
    },

    // ── derived ──
    sortedEntries() {
      let entries = Object.values(this.currentLeaderboard)
        .filter((e) => this._passesFilters(e))
        .sort((a, b) => b.score - a.score)
        .map((entry, i) => ({ ...entry, position: i + 1 }));
      if (!this.showAll) entries = this._snipTableData(entries);
      return entries;
    },

    sortedEntriesHtml() {
      const entries = this.sortedEntries();
      return entries
        .map((entry) => {
          const rowClass = this.entryRowClass(entry);
          const contextual = this.contextualCell(entry);
          return `<tr id="row-${entry.id}"${rowClass ? ` class="${rowClass}"` : ""}>
          <td id="pos-${entry.id}">${entry.position}</td>
          <td id="icon-${entry.id}">${this.iconHtml(entry)}</td>
          <td id="name-${entry.id}">${escapeHtml(entry.name)}</td>
          <td id="awards-${entry.id}">${this.awardStarsHtml(entry.awards)}</td>
          <td class="d-none d-lg-block" id="${entry.id}-contextual">${escapeHtml(contextual)}</td>
          <td id="score-${entry.id}">${entry.score}</td>
        </tr>`;
        })
        .join("");
    },

    _passesFilters(entry) {
      const userSchool = this.user.school;
      let schoolFilterSet = false;

      for (const f of this.currentFilters) {
        if (
          f.name === "Schools" &&
          f.option !== "All" &&
          entry.school_name !== f.option
        ) {
          return false;
        }
        if (f.name === "Class" && f.option !== "All") {
          if (
            entry.classroom_names == null ||
            !entry.classroom_names.includes(f.option) ||
            entry.school_name !== userSchool
          ) {
            return false;
          }
        }
        if (f.name === "Schools") schoolFilterSet = true;
      }

      if (!schoolFilterSet && entry.school_name !== userSchool) {
        return false;
      }
      return true;
    },

    _snipTableData(entries) {
      const size = entries.length;
      const max = MAX_USERS_TO_DISPLAY;
      const userIndex = entries.findIndex((e) => e.id === this.user.id);

      if (size < max - 1) return entries;
      if (userIndex < max) return entries.slice(0, max);
      if (userIndex + max / 2 >= size) return entries.slice(size - max);
      const lower = Math.max(0, userIndex - max / 2 + 1);
      const upper = Math.min(size, lower + max);
      return entries.slice(lower, upper);
    },

    classroomFilterOptions() {
      return ["All", ...this.classrooms];
    },

    schoolFilterOptions() {
      if (this.schools.length <= 1) return [];
      return ["All", ...this.schools];
    },

    selectedFilterText(name, fallback) {
      const filter = this.currentFilters.find((f) => f.name === name);
      return filter ? filter.option : fallback;
    },

    contextualHeader() {
      return this.currentFilters.some((f) => f.name === "Schools")
        ? "School"
        : "Class";
    },

    contextualCell(entry) {
      if (this.currentFilters.some((f) => f.name === "Schools")) {
        return entry.school_name || "";
      }
      return (entry.classroom_names || []).join(", ");
    },

    winnerClassroom() {
      const classFilter = this.currentFilters.find((f) => f.name === "Class");
      if (classFilter) {
        return classFilter.option === "All"
          ? this.user.classrooms?.[0]
          : classFilter.option;
      }
      return this.user.classrooms?.[0];
    },

    winnerLabel() {
      const classroom = this.winnerClassroom();
      return this.winners
        .filter((w) => w[0] === classroom)
        .map((w) => `${w[1]} - ${w[2]} points`)
        .join(", ");
    },

    awardStarsHtml(awardsCount) {
      let html = "";
      let remaining = awardsCount || 0;
      while (remaining >= 5) {
        html +=
          '<i class="fas fa-star" style="color: gold;" title="Five wins!"></i>';
        remaining -= 5;
      }
      while (remaining >= 3) {
        html +=
          '<i class="fas fa-star" style="color: silver;" title="Three wins!"></i>';
        remaining -= 3;
      }
      while (remaining >= 1) {
        html +=
          '<i class="fas fa-star" style="color: red;" title="Came top of the leaderboard once!"></i>';
        remaining -= 1;
      }
      return html;
    },

    entryRowClass(entry) {
      const classes = [];
      if (entry.lastChanged) classes.push("score-changed");
      if (this.user.id === entry.id) {
        classes.push("font-weight-bold", "current-user");
      }
      return classes.join(" ");
    },

    iconHtml(entry) {
      if (!entry.icon) return "";
      const [color, name] = entry.icon.split(",");
      return `<i class="fas fa-${escapeHtml(name)}" style="color: ${escapeHtml(color)};"></i>`;
    },
  }),
);
