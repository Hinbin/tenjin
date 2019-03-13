$(document).on('turbolinks:load', function () {
  if (page.controller() === 'leaderboard') {
    App.leaderboard = App.cable.subscriptions.create({ channel: 'LeaderboardChannel', subject: gon.subject, school: gon.school, school_group: gon.school_group }, {
      connected () {

      },
      // Called when the subscription is ready for use on the server

      disconnected () { },
      // Called when the subscription has been terminated by the server

      received (data) {

        // If this isn't for the topic being shown, return and do nothing   
        if (gon.topic !== undefined && data.topic !== gon.topic) {
          return
        }

        window.leaderboard.scoreChanged(data)
      }
    })
  }
})
