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

params = {
    TableName: "mafia-game",
};

module.exports = (robot) ->
  # robot.hear /private hello/i, (res) ->
  #   res.envelope.pm = true
  #   res.send "I will reply hello privately!"

  # UNLYNCH COMMAND
  robot.respond /unlynch/i, (res) ->
    voter =  res.envelope.user.username
    day_id = res.message.room

    result = getDay(day_id)
    result.then (data) ->
      if (data.Count > 0 )
        valid = isUnLynch(data.Items, voter)
        if (valid)
          unLynch(day_id, voter)

  # LYNCH COMMAND
  robot.respond /lynch (.*)/i, (res) ->

    voter =  res.envelope.user.username
    lynch = res.match[1]
    threadId = res.message.room
    result = getDay(day_id)
    result.then (data) ->
      if (data.Count > 0 )
        valid = isLynch(data.Items , voter, lynch)
        if (valid)
          updateLynch(threadId, voter, lynch)

  # VOTE COUNT COMMAND
  robot.respond /votecount/i, (res) ->
    response = ''
    notVoting = ''
    result = getDay(res.message.room)
    result.then (data) ->
      for item in data.Items
        for player in item.alive_players
          if item["votes"][player]
            if item["votes"][player]['vote'] is null
              notVoting += player + "\n"
            else
              response += "|" + item["votes"][player]['voter'] + "| " + item["votes"][player]['vote'] + "|\n"
          else
            notVoting += player + "\n"
      res.send(printVote(response, notVoting))

  # VOTE COUNT ALIAS
  robot.respond /vc/i, (res) ->
    response = ''
    notVoting = ''
    result = getDay(res.message.room)
    result.then (data) ->
      for item in data.Items
        for player in item.alive_players
          if item["votes"][player]
            if item["votes"][player]['vote'] is null
              notVoting += player + "\n"
            else
              response += "|" + item["votes"][player]['voter'] + "| " + item["votes"][player]['vote'] + "|\n"
          else
            notVoting += player + "\n"
      res.send(printVote(response, notVoting))

  # Host Game
  robot.respond /host/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 0
        #Add Game if no matching #ID
        hostGame(res.envelope.user.username, res.message.title, res.message.room)

  # Sign to Game Game
  robot.respond /sign/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)

  # Sign to Game Game
  robot.respond /kill (.*)/i, (res) ->

    host =  res.envelope.user.username
    target = res.match[1]
    threadId = res.message.room

    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if host is item.host
            killPlayer(threadId, item.kills, target)

  # Sign to Game Game
  robot.respond /\.s/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)

  # Sign to Game Game
  robot.respond /unsign/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          unSignGame(res.envelope.user.username, res.message.room, item.signed_players)

  # Show Signed Players
  robot.respond /slist/i, (res) ->
    result = getGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if item.signed_players
            res.send(printSignedPlayers(item.signed_players))
          else
            res.send(printSignedPlayers("Sign the Fuck up you cucks"))
  # Start Day
  robot.respond /startday (.*)/i, (res) ->
    #Get Days
    parentId = res.match[1]
    host =  res.envelope.user.username
    title = res.message.title
    threadId = res.message.room

    result = getDaysOfParent(parentId)
    result.then (data) ->
          # If no days create day 1
      if data.Count is 0
        parent = getGame(parentId)
        parent.then (gameData) ->
          if gameData.Count is 1
            for item in gameData.Items
              if host is item.host
                startGame(host, title, threadId, item.signed_players, parentId)
      # Else get last day and create new day
      else
        console.log data.Count
        index = data.Count
        index -= 1
        console.log index
        console.log data.Items[index]
       if host is data.Items[index].host
        startDay(host, title, threadId, parentId, data.Items[index])

  # ZEUS COMMAND - Will remove player from active list eventually
  robot.respond /zeus (.*)/i, (res) ->
    res.send(getZeused(res.match[1]))

# Functions

printVote = (votes, notVoting) ->
  response = "# Vote Count"
  response += "\n --- \n"
  response += "| Player  | Lynches  | \n"
  response += "|---|---|\n"
  response += votes
  response += "\n ##  Not Voting"
  response += "\n --- \n"
  response += notVoting
  response += "\n --- \n"
  response += uuidv1()

  return response

printSignedPlayers = (signed) ->

  response = "#  Signed Players"
  response += "\n --- \n"
  for player in signed
      response += player + "\n"
  response += "\n --- \n"
  response += uuidv1()

  return response

getZeused = (playerName) ->
  response = ":zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus:\n"
  response += "\-\(&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\)\n
       \(&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\_\)\n
      \(\-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\-\-\)\n
      &nbsp;\(&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\-\-\-\-\-\)\n
      &nbsp;&nbsp;&nbsp;&nbsp;\(\-\-\-\-\-\-\-\-\-\)\-\-\-\-\'\n
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\-\/&nbsp;&nbsp;\/\n
      &nbsp;&nbsp;&nbsp;&nbsp;\/&nbsp;&nbsp;&nbsp;\-\/\n
      &nbsp;&nbsp;&nbsp;&nbsp;\-\/&nbsp;&nbsp;\/\n
      &nbsp;&nbsp;&nbsp;\/&nbsp;\-\-\/\n
      &nbsp;\-\/&nbsp;&nbsp;\/\n
      \/\-\-\/\n
     \/\/\n
    \/\'\n"
  response += playerName + " is struck down by his god\n"

  response+= ':zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus:'

  return response

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

isLynch = (game, user, target) ->

  # False means the day is not over.
  if game[0].status is false
    # Then we check if user and target are both alive players
    if user and target in game[0].alive_players
      return true
    else
      return false
  else
   return false

isUnLynch = (game, user) ->

  # False means the day is not over.
  if game[0].status is false
    # Then we check if user and target are both alive players
    if user in game[0].alive_players
      return true
    else
      return false
  else
   return false

updateLynch = (day_id, voter, lynch) ->

  # Get timestamp of Vote
  dt = new Date();

  # Build new Query
  query = {}
  query.TableName = "mafia-day"
  query.Key = {
    "day_id": day_id
  }
  query.UpdateExpression = "set votes."+voter+".vote = :l, votes."+voter+".vote_time = :t"
  query.ExpressionAttributeValues = {
    ":l":lynch,
    ":t":dt.getTime()
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data

unLynch = (day_id, voter) ->

  # Get timestamp of Vote
  dt = new Date();

  # Build new Query
  query = {}
  query.TableName = "mafia-day"
  query.Key = {
    "day_id": day_id
  }
  query.UpdateExpression = "set votes."+voter+".vote = :l, votes."+voter+".vote_time = :t"
  query.ExpressionAttributeValues = {
    ":l": null,
    ":t":dt.getTime()
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data

hostGame = (host, title, threadId) ->
  dt = new Date();
  query = {}
  query.TableName = "mafia-game"
  query.Item = {
         game_id: threadId,
         game_start: dt.getTime(),
         game_url: "https://namafia.com/t/" + title + "/" + threadId,
         status: false,
         title: title,
         host: host
  }
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

startGame = (host, title, threadId, players, parent) ->

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
         day_url: "https://namafia.com/t/" + title + "/" + threadId,
         status: false,
         day_title: title,
         host: host,
         votes: votes,
         alive_players: players,
         day: 1,
         parent_id: parent
  }

  console.log query
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

startDay = (host,title,threadId, parent, data) ->
  # Subject Kills from Alive Players
  alive_players = data.alive_players
  for killedPlayer in data.kills
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
         day_url: "https://namafia.com/t/" + title + "/" + threadId,
         status: false,
         day_title: title,
         host: host,
         votes: votes,
         day: data.Count,
         parent_id: parent,
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

killPlayer = (threadId, kills, target) ->
  if kills
    if target not in kills
      kills.push target
  else
    kills = []
    kills.push target
  # Build new Query
  query = {}
  query.TableName = "mafia-day"
  query.Key = {
    "day_id": threadId
  }
  query.UpdateExpression = "set kills = :k"
  query.ExpressionAttributeValues = {
    ":k":kills,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data
