var helpFunctions = require("./../src/helpers/help.coffee");


module.exports = (robot) ->

  # General Help
  robot.hear /@mafiabot help/i, (res) ->
    console.log "TEST"
    res.send(helpFunctions.generalHelp())

  robot.hear /@mafiabot man/i, (res) ->
    res.send(helpFunctions.generalHelp())

  robot.hear /@mafiabot host help/i, (res) ->
    res.send(helpFunctions.hostHelp())

  robot.hear /@mafiabot man host/i, (res) ->
    res.send(helpFunctions.hostHelp())

  robot.hear /@mafiabot man player/i, (res) ->
    res.send(helpFunctions.playerHelp())
