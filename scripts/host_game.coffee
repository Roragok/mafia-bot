# Description:
#  This file contains the needed command to start a signup of a mafia game.
#  host creats the game
# sign, .s - sign the game
# unsign - removes from the game
# slist - shows list of signed players
#

uuidv1 = require 'uuid/v1'
AWS = require 'aws-sdk'

AWS.config.update({
  region: "us-east-1",
  endpoint: "https://dynamodb.us-east-1.amazonaws.com"
})

docClient = new AWS.DynamoDB.DocumentClient()


module.exports = (robot) ->

  # Host Game
  robot.hear /@mafiabot host/i, (res) ->
    # id of thread
    threadId = res.message.room

    # user who triggered command
    user = res.envelope.user.username

    # Thread Title
    threadTitle=  res.message.title

    # url of game
    game_slug = res.message.slug

    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 0
        #Add Game if no matching #ID
        hostGame(user,threadTitle, threadId, game_slug)

  # Sign Game
  robot.hear /@mafiabot sign/i, (res) ->
    threadId = res.message.room
    user = res.envelope.user.username
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(user, threadId, item.signed_players)

  # Sign Game
  robot.hear /@mafiabot \.s/i, (res) ->
    threadId = res.message.room
    user = res.envelope.user.username
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(user, threadId, item.signed_players)

  # UnSign Game
  robot.hear /@mafiabot unsign/i, (res) ->
    threadId = res.message.room
    user = res.envelope.user.username
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          unSignGame(user, threadId, item.signed_players)

  # Show Signed Players
  robot.hear /@mafiabot slist/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if item.signed_players
            res.send(printSignedPlayers(item.signed_players))
          else
            res.send(("# Signed Players \n ---
            \n Sign the Fuck up you cucks \n"))

  # Add a Signed Players
  robot.hear /@mafiabot add (.*)/i, (res) ->
    host =  res.envelope.user.username
    target = res.match[1] . replace '@', ''
    threadId = res.message.room

    result = getGame(threadId)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Remove User to Signup
          if host is item.host
            signGame(target, threadId, item.signed_players)

  # Remove a Signed Players
  robot.hear /@mafiabot remove (.*)/i, (res) ->
    host =  res.envelope.user.username
    target = res.match[1] . replace '@', ''
    threadId = res.message.room

    result = getGame(threadId)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Remove User to Signup
          if host is item.host
            unSignGame(target, threadId, item.signed_players)

  # Enable/Disable Autolocking
  # Game threads will inheirt the master thread,
  # but can be individually disabled
  robot.hear /@mafiabot autolock/i, (res) ->
    # id of thread
    threadId = res.message.room
    # user who triggered command
    host = res.envelope.user.username
    result = getGame(threadId)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Remove User to Signup
          if host is item.host
            autolockGame(threadId,item.autolock)
      else
        result = getDay(threadId)
        result.then (data) ->
          if data.Count is 1
            for item in data.Items
              # Remove User to Signup
              if host is item.host
                autolockDay(threadId,item.autolock)



#  Prints the list of signed players
printSignedPlayers = (signed) ->

  response = "#  Signed Players"
  response += "\n --- \n"
  for player in signed
    response += player + "\n"
  response += "\n --- \n"
  response += uuidv1()

  return response


#  Inserts a game entry into mafia-game Table
#  @params -
#  host- moderator of game
#  title - thread title where game is created
#  threadId - id of game created based on thread id of discourse
#  game_slug - url of created game
hostGame = (host, title, threadId, game_slug) ->
  dt = new Date()
  query = {}
  query.TableName = "mafia-game"
  query.Item = {
   game_id: threadId,
   game_start: dt.getTime(),
   game_url: game_slug,
   status: false,
   title: title,
   host: host,
   autolock: true
  }
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

#  Adds a player to the signed player list.
#  @params -
#  user - name of user signing game
#  threadId - id of game created based on thread id of discourse
#  players - string array of current signed players
signGame = (user, threadId, players) ->

  if players
    if user not in players
      players.push user
  else
    players = []
    players.push user
  # Build new Query
  query = {}
  query.TableName = "mafia-game"
  query.Key = {
    "game_id": threadId
  }
  query.UpdateExpression = "set signed_players = :p"
  query.ExpressionAttributeValues = {
    ":p":players,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data

#  Removes a player to the signed player list.
#  @params -
#  user - name of user unsigning game
#  threadId - id of game created based on thread id of discourse
#  players - string array of current signed players
unSignGame = (user, threadId, players) ->
  index = null
  index = players.indexOf(user)
  if index or index is 0
    players.splice(index, 1)

  # Build new Query
  query = {}
  query.TableName = "mafia-game"
  query.Key = {
    "game_id": threadId
  }
  query.UpdateExpression = "set signed_players = :p"
  query.ExpressionAttributeValues = {
    ":p":players,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data

#  Returns a Game from mafia-game table based on a threadId
#  @params -
#  user - Thrad ID of game to lookup
getGame = (threadId) ->

  # Build Query
  checkGame = {}
  checkGame.TableName = "mafia-game"
  checkGame.KeyConditionExpression = "game_id = :game_id"
  checkGame.ExpressionAttributeValues = {
    ":game_id": parseInt threadId
  }
  result = docClient.query(checkGame).promise()

# Check if thread came from is an active or past game.
getDay = (threadId) ->

  # Build Query
  checkGame = {}
  checkGame.TableName = "mafia-day"
  checkGame.KeyConditionExpression = "day_id = :day_id"
  checkGame.ExpressionAttributeValues = {
    ":day_id": threadId
  }

  result = docClient.query(checkGame).promise()

#  Changes boolean on autolock of thread
#  @params -
#  threadId - id of game created based on thread id of discourse
#  autolock - current autolock status
autolockGame = (threadId,autolock) ->

  if autolock
    autolock = false
  else
    autolock = true

  # Build new Query
  query = {}
  query.TableName = "mafia-game"
  query.Key = {
    "game_id": threadId
  }
  query.UpdateExpression = "set autolock = :p"
  query.ExpressionAttributeValues = {
    ":p":autolock,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data

#  Changes boolean on autolock of thread
#  @params -
#  threadId - id of game created based on thread id of discourse
#  autolock - current autolock status
autolockDay = (threadId,autolock) ->
  if autolock
    autolock = false
  else
    autolock = true

  # Build new Query
  query = {}
  query.TableName = "mafia-day"
  query.Key = {
    "day_id": threadId
  }
  query.UpdateExpression = "set autolock = :p"
  query.ExpressionAttributeValues = {
    ":p":autolock,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data
