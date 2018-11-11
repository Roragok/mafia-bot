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
    day_id = res.message.room
    if voter isnt lynch
      result = getDay(day_id)
      result.then (data) ->
        if (data.Count > 0 )
          valid = isLynch(data.Items , voter, lynch)
          if (valid)
            updateLynch(day_id, voter, lynch)

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
  robot.hear /@mafiabot vc/i, (res) ->
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
    result = checkGame(res.message.room)
    result.then (data) ->
      console.log data
      if data.Count is 0
        #Add Game if no matching #ID
        hostGame(res.envelope.user.username, res.message.title, res.message.room)


  # Sign to Game Game
  robot.respond /sign/i, (res) ->
    result = checkGame(res.message.room)
    result.then (data) ->
      console.log data
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)

  # Sign to Game Game
  robot.respond /\.s/i, (res) ->
    result = checkGame(res.message.room)
    result.then (data) ->
      if data.Count is 1
        for item in data.Items
          # Add User to Signup
          signGame(res.envelope.user.username, res.message.room, item.signed_players)


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

checkGame = (threadId) ->
  # Build Query
  checkGame = {}
  checkGame.TableName = "mafia-game"
  checkGame.KeyConditionExpression = "game_id = :game_id"
  checkGame.ExpressionAttributeValues = {
    ":game_id": threadId
  }

  result = docClient.query(checkGame).promise()

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
         title: title
  }
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

signGame = (user, threadId, players) ->
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


# Check if thread came from is an active or past game.
getVotes = (threadId) ->
  votes = {}
  votes.TableName = "mafia-day"
  result = docClient.scan(votes).promise()

# Check if the person who sent the command is a host or moderator.
isHost = (threadID) ->
  return true
