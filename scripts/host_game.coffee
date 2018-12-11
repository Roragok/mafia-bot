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
});

docClient = new AWS.DynamoDB.DocumentClient();


module.exports = (robot) ->

  # Host Game
  robot.hear /@mafiabot host (.*)/i, (res) ->
    if res.match[1].toString().toLowerCase() not "help"
      game_slug = res.message.slug
      result = getGame(res.message.room)
      result.then (data) ->
        if data.Count is 0
          #Add Game if no matching #ID
          hostGame(res.envelope.user.username, res.message.title, res.message.room, game_slug)
    else
      res.send(hostHelp())

  # Sign Game
  robot.hear /@mafiabot sign/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)

  # Sign Game
  robot.hear /@mafiabot \.s/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)

  # UnSign Game
  robot.hear /@mafiabot unsign/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          unSignGame(res.envelope.user.username, res.message.room, item.signed_players)

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
            res.send(("# Signed Players \n --- \n Sign the Fuck up you cucks \n"))



printSignedPlayers = (signed) ->

  response = "#  Signed Players"
  response += "\n --- \n"
  for player in signed
      response += player + "\n"
  response += "\n --- \n"
  response += uuidv1()

  return response

hostGame = (host, title, threadId, game_slug) ->
  dt = new Date();
  query = {}
  query.TableName = "mafia-game"
  query.Item = {
         game_id: threadId,
         game_start: dt.getTime(),
         game_url: game_slug,
         status: false,
         title: title,
         host: host
  }
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data


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

getGame = (threadId) ->

  # Build Query
  checkGame = {}
  checkGame.TableName = "mafia-game"
  checkGame.KeyConditionExpression = "game_id = :game_id"
  checkGame.ExpressionAttributeValues = {
    ":game_id": parseInt threadId
  }
  result = docClient.query(checkGame).promise()

hostHelp = () ->
  response = "The host of a Mafia game can use the following commands\n"
  response += "* `@mafiabot host` - Takes the current thread and create a signup\n"
  response += "* `@mafiabot startday THREAD_ID`- Starts first or next day of your game.  `THREAD_ID` is very important and must be the ID of the game the `host` command was excuted from\n"
  response += "* `@mafiabot kill playername`- Kills `playername` This command must be excuted in the current day before you run the nextstartday command.  Must be excuted 1 time per player and is case sensitive.  This removes the player from the alive player list when the next `startday` command is excuted\n"
  return response
