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
    // Called when there's incoming data on the websocket for this channel
    const doc = document.getElementById('leaderboard');
    const user = document.getElementById(data.user);
    const userScore = data.subject_score;
    console.log(data)
    if (user != null) {
      return user.innerHTML = userScore;
    }
  }
}
);
      
    
