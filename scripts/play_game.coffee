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
  # robot.hear /private hello/i, (res) ->
  #   res.envelope.pm = true
  #   res.send "I will reply hello privately!"

  # UNLYNCH COMMAND
  robot.hear /@mafiabot unlynch/i, (res) ->
    voter =  res.envelope.user.username
    threadId = res.message.room

    result = getDay(threadId)
    result.then (data) ->
      if (data.Count > 0 )
        valid = isUnLynch(data.Items, voter)
        if (valid)
          unLynch(threadId, voter)

  # LYNCH COMMAND
  robot.hear /@mafiabot lynch (.*)/i, (res) ->
    voter =  res.envelope.user.username
    lynch = res.match[1]  . replace '@', ''
    threadId = res.message.room
    result = getDay(threadId)
    result.then (data) ->
      if (data.Count > 0 )
        valid = isLynch(data.Items , voter, lynch)
        if (valid)
          updateLynch(threadId, voter, lynch)

  # LYNCH ALIAS
  robot.hear /@mafiabot vote (.*)/i, (res) ->
    voter =  res.envelope.user.username
    lynch = res.match[1]  . replace '@', ''
    threadId = res.message.room
    result = getDay(threadId)
    result.then (data) ->
      if (data.Count > 0 )
        valid = isLynch(data.Items , voter, lynch)
        if (valid)
          updateLynch(threadId, voter, lynch)

  # VOTE COUNT COMMAND
  robot.hear /@mafiabot votecount/i, (res) ->
    votes = []
    notVoting = ''
    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count > 0
        for item in data.Items
          for player in item.alive_players
            if item["votes"][player]
              if item["votes"][player]['vote'] is null
                notVoting +=  player + ", ";
              else
                votes[item["votes"][player]['vote']] += item["votes"][player]['voter'] + ", "
                # votes += "|" + item["votes"][player]['voter'] + "| " + item["votes"][player]['vote'] + "|\n"
            else
              notVoting += player + "\n"
        res.send(printVote(votes, notVoting))

  # VOTE COUNT ALIAS
  robot.hear /@mafiabot vc/i, (res) ->
    votes = []
    notVoting = ''
    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count > 0
        for item in data.Items
          for player in item.alive_players
            if item["votes"][player]
              if item["votes"][player]['vote'] is null
                notVoting +=  player + ", ";
              else
                console.log item["votes"][player]['voter'] + "\n"
                voted = item["votes"][player]['vote'];
                votes.voted.push item["votes"][player]['voter']
                console.log votes + "\n"
                # votes += "|" + item["votes"][player]['voter'] + "| " + item["votes"][player]['vote'] + "|\n"
            else
              notVoting += player + "\n"
        res.send(printVote(votes, notVoting))

  # HOST COMMANDS

  # Host Kills a player in the current Day
  robot.hear /@mafiabot kill (.*)/i, (res) ->

    host =  res.envelope.user.username
    target = res.match[1] . replace '@', ''
    threadId = res.message.room

    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if host is item.host
            killPlayer(threadId, item.kills, target)

  # HOST Subs a player in the current Day

  robot.hear /@mafiabot sub (.*)/i, (res) ->

    host =  res.envelope.user.username
    targets = res.match[1] . replace '@', '' . split " "
    threadId = res.message.room

    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if host is item.host
            subPlayer(threadId, item.alive_players, targets)

  # ZEUS COMMAND - Will remove player from active list eventually
  robot.hear /@mafiabot zeus (.*)/i, (res) ->
    host =  res.envelope.user.username
    target = res.match[1]  . replace '@', ''
    threadId = res.message.room

    result = getDay(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          if host is item.host
            killPlayer(threadId, item.kills, target)
            res.send(getZeused(target))


# Functions

printVote = (votes, notVoting) ->
  response = "# Vote Count"
  response += "\n --- \n"
  response += "| Player  | Lynches  | \n"
  response += "|---|---|\n"
  for voters, target in votes
    response +=  "|" + target  + "| " + voters + "|\n"
  # response += votes
  response += "\n ##  Not Voting"
  response += "\n --- \n\n"
  response += notVoting
  response += "\n\n --- \n"
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

isLynch = (game, user, target) ->

  # False means the day is not over.
  if game[0].status is false
    # Then we check if user and target are both alive players
    if (user in game[0].alive_players) and (target is "nolynch")
      #if user and target in game[0].alive_players
      return true
    else if user in game[0].alive_players
      for player in game[0].alive_players
        if player.toLowerCase() is target.toLowerCase()
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

subPlayer = (threadId, alive_players, targets) ->
  # if alive_players
  #   for targets[0], keyz in alive_players
  #     alive_players[keyz] = targets[1]

  # Build New Query
  query = {}
  query.TableName = "mafia-day"
  query.Key = { "day_id": threadId }
  query.UpdateExpression = "set alive_players = :ap"
  query.ExpressionAttributeValues = {
    ':ap':alive_players,
  }

  docClient.update query, (err, data) ->
    if err
      console.log err
    else
      console.log data
