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
      console.log data.Count
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
        index -= 1
        console.log index
        console.log  data.Items[index].day_title
        console.log " BREAL AMD THINGS"
       if host is data.Items[index].host
        startDay(host, title, threadId, parentId, data.Items[index], game_slug)


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

  console.log query
  docClient.put query, (err, data) ->
    if err
      console.log err
    else
      console.log data

startDay = (host,title,threadId, parent, data, game_slug) ->
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
  count = data.Count
  console.log count
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
         day: count,
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
