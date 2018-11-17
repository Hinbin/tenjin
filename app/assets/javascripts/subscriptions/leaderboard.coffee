App.leaderboard = App.cable.subscriptions.create {channel: 'LeaderboardChannel', subject: gon.subject, school: gon.school},
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    doc = document.getElementById('leaderboard')
    user = document.getElementById(data.user)
    userName = data.user
    userScore = data.subject_score
    console.log(data)

    if user?
      user.innerHTML = userName + ' - ' + userScore
    else 
      doc.innerHTML = doc.innerHTML + '<li id=' + userName + '>' + userName + ' - ' + userScore + '</li>'
      
    
