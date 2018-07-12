App.leaderboard = App.cable.subscriptions.create { channel: "LeaderboardChannel", subject: "Computer Science" },
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    doc = document.getElementById('leaderboard')
    doc.innerHTML = data.score
    console.log(data)
    
