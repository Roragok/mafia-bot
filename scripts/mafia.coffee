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
  robot.hear /private hello/i, (res) ->
    res.envelope.pm = true
    res.send "I will reply hello privately!"


  robot.hear /@mafiabot lynch/i, (res) ->
    res.reply "Lynch Recorded, but not really."

  robot.hear /@mafiabot unlynch/i, (res) ->
    res.reply "Unlynched."

  robot.response /votecount/i, (res) ->
    response = ''
    docClient.scan params, (err, data) ->
      for item in data.Items
        response += "|" + item['title'] + "| " + item['status'] + "|"
      res.send(printVote(response))

  robot.hear /@mafiabot vc/i, (res) ->
    response = ''
    docClient.scan params, (err, data) ->
      for item in data.Items
        response += "|" + item['title'] + "| " + item['status'] + "|\n"
      res.send(printVote(response))

  robot.hear /@mafiabot addgame/i, (res) ->
    dt = new Date();

    query = params
    query.Item = {
           game_id: res.message.room,
           game_start: dt.getTime(),
           game_url: "https://namafia.com/t/"+res.message.title+ "/" + res.message.room,
           status: false,
           title: res.message.title
    }
    docClient.put query, (err, data) ->
      if err
        console.log err
      else
        console.log data

  robot.response /zeus (.*)\s/i, (res) ->
    res.send(getZeused(res.match[1]))

printVote = (votes) ->
  response = "# Vote Count"
  response += "\n --- \n"
  response += "| Player  | Lynches  | \n"
  response += "|---|---|\n"
  response += votes
  response += "\n ##  Not Voting"
  response += "\n --- \n"
  response += uuidv1()

  return response

getZeused = (playerName) ->
  response = '
    :zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus:
    \`\`\`
        _(                        )
       (                          _)
      (_                       __))
        ((                _____)
          (_________)----\'
             _/  /
            /  _/
          _/  /
         / __/
       _/ /
      /__/
     //
    /\'
    \`\`\`'
  response += playerName + " is struck down by his god\n"

  response+= ':zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus::zeus:'

  return response
