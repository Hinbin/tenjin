/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
App.leaderboard = App.cable.subscriptions.create({channel: 'LeaderboardChannel', subject: gon.subject, school: gon.school}, {
  connected() {},
    // Called when the subscription is ready for use on the server

  disconnected() {},
    // Called when the subscription has been terminated by the server

  received(data) {
    
    // If this isn't for the topic being shown, return and do nothing
    if (gon.topic !== null && data.topic !== gon.topic)
      return

    // Called when there's incoming data on the websocket for this channel
    let tableScore = document.getElementById('score-' + data.user)
    
    let newScore = 0
    if (gon.topic === null) {
      console.log(data.subject_score)
      newScore = data.subject_score
    }
    else
      newScore = data.topic_score
  
    if (tableScore != null) {
      let scoreRow = $('#row-' + data.user)
      // Updates the table and adds the score-changed class to cause 
      // the row to flash
      $(tableScore).updateSortVal(newScore)
      tableScore.innerHTML = newScore
      $(scoreColumn).stupidsort('desc')
      $(scoreRow).addClass('score-changed')

      setTimeout( () => {
        $(scoreRow).removeClass('score-changed')
      }, 1010)
  }
}
});
      
    
