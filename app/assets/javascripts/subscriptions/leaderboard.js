$(document).on('turbolinks:load', function () {
  if (page.controller() === 'leaderboard') {
    App.leaderboard = App.cable.subscriptions.create({ channel: 'LeaderboardChannel', subject: window.gon.subject, school: window.gon.school, school_group: window.gon.school_group }, {
      connected () {

      },
      // Called when the subscription is ready for use on the server

      disconnected () { },
      // Called when the subscription has been terminated by the server

      received (data) {

        console.log(data)
        // If this isn't for the topic being shown, return and do nothing   
        if (window.gon.topic === undefined) {
          window.leaderboard.scoreChanged(data, 'ALL')
        } else if (data.topic === window.gon.topic) {
          window.leaderboard.scoreChanged(data, 'TOPIC')
        }        
      }
    })
  }
})
