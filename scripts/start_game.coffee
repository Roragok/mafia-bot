# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

uuidv1 = require 'uuid/v1'
AWS = require 'aws-sdk'

AWS.config.update({
  region: "us-east-1",
  endpoint: "https://dynamodb.us-east-1.amazonaws.com"
});

docClient = new AWS.DynamoDB.DocumentClient();

module.exports = (robot) ->
  # Start Day
  robot.hear /@mafiabot startday (.*)/i, (res) ->
    #Get Days
    parentId = res.match[1]
    host =  res.envelope.user.username
    title = res.message.title
    threadId = res.message.room
    game_slug = res.message.slug

    result = getDaysOfParent(parentId)
    result.then (data) ->
      # If no days create day 1
      if data.Count is 0
        parent = getGame(parentId)
        parent.then (gameData) ->
          if gameData.Count is 1
            for item in gameData.Items
              if host is item.host
                startGame(host, title, threadId, item.signed_players, parentId, game_slug)
      # Else get last day and create new day
      else
        index = data.Count
        if host is data.Items[0].host
          for day in data.Items
            if index is day.day
              # host, thread_title, thread_id, parent_game_id, alive,players, kills, day
              # startDay(host, title, threadId, parentId, data.Items[index].alive_players, data.Items[0].kills, index+1, game_slug)
              startDay(host, title, threadId, parentId,day.alive_players,day.kills, index+1, game_slug)
              #  Set Previous Day to status to true for complete.
              closeDay(day.day_id)
  # End Day
  robot.hear /@mafiabot end (.*)/i, (res) ->

    winner = res.match[1]
    host =  res.envelope.user.username
    threadId = res.message.room

    result = getDay(threadId)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          if host is item.host
            # Update Game with Winning Faction and set status to true for completed game.
            closeDay(threadId)
            endGame(item.parent_id, winner)


startGame = (host, title, threadId, players, parent, game_slug) ->

  dt = new Date();
  timestamp = dt.getTime()
  votes = {}
  for player in players
    votes[player] = {
      vote: null,
      voter:player,
      vote_time: timestamp
    }

  query = {}
  query.TableName = "mafia-day"
  query.Item = {
         day_id: threadId,
         day_start: timestamp,
         day_url: game_slug,
         status: false,
         day_title: title,
         host: host,
         votes: votes,
         alive_players: players,
         day: 1,
         parent_id: parent
  }

  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

startDay = (host, title, threadId, parent, alive_players, kills, day, game_slug) ->
  # Subject Kills from Alive Players

  for killedPlayer in kills
    index = null
    index = alive_players.indexOf(killedPlayer)
    if index or index is 0
      alive_players.splice(index, 1)

  dt = new Date();
  timestamp = dt.getTime()
  votes = {}
  for player in alive_players
    votes[player] = {
      vote: null,
      voter:player,
      vote_time: timestamp
    }
  query = {}
  query.TableName = "mafia-day"
  query.Item = {
         day_id: threadId,
         alive_players: alive_players,
         day_start: timestamp,
         day_url: game_slug,
         status: false,
         day_title: title,
         host: host,
         votes: votes,
         day: day,
         parent_id: parent,
  }
  docClient.put query, (err, data) ->
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

# Check if thread came from is an active or past game.
getDaysOfParent = (threadId) ->

  # Build Query
  getParent = {}
  getParent.TableName = "mafia-day"
  getParent.IndexName = "parent_id-index"
  getParent.KeyConditionExpression = "parent_id = :parent_id"
  getParent.ExpressionAttributeValues = {
    ":parent_id": threadId
  }

  result = docClient.query(getParent).promise()

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

# Set Previous Day status to true.
closeDay = (day_id) ->
  query = {}
  query.TableName = "mafia-day"
  query.Key = {
    "day_id": day_id
  }
  query.UpdateExpression = "set #status = :status"
  query.ExpressionAttributeNames = {
    "#status": "status",
  }
  query.ExpressionAttributeValues = {
    ":status": true,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data


# End Game
# Set Previous Day status to true.
endGame = (parent_id,winner) ->

  result = switch winner.toLowerCase()
   when "mafia","werewolf","wolf" then "Mafia"
   when "town","village" then "Town"
   when "third" then "Third Party"
   else "unkown"

  query = {}
  query.TableName = "mafia-game"
  query.Key = {
    "game_id": parseInt parent_id
  }
  query.UpdateExpression = "set #winner = :winner, #status = :status"
  query.ExpressionAttributeNames = {
    "#winner": "winner",
    "#status": "status"
  }
  query.ExpressionAttributeValues = {
    ":winner": result,
    ":status": true,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data
