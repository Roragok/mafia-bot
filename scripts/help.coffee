#helpFunctions = require("./../src/helpers/help");


module.exports = (robot) ->

  # General Help
  robot.hear /@mafiabot help/i, (res) ->
    console.log "TEST"
    res.send(generalHelp())

  robot.hear /@mafiabot man/i, (res) ->
    res.send(generalHelp())

  robot.hear /@mafiabot help host /i, (res) ->
    res.send(hostHelp())

  robot.hear /@mafiabot man host/i, (res) ->
    res.send(hostHelp())

  robot.hear /@mafiabot help player/i, (res) ->
    res.send(playerHelp())

  robot.hear /@mafiabot man player/i, (res) ->
    res.send(playerHelp())





  generalHelp = () ->
    response = "Please use the following commands to specfiy advanced help\n"
    response += "* `@mafiabot host help` - Detailed Information about Hosting a game\n"
    response += "* `@mafiabot player help`- Detailed Information about Playing a game\n"
    response += "* `@mafiabot help`- This help command\n"
    return response

  hostHelp = () ->
    response = "Please use the following commands to specfiy advanced help\n"
    response += "* `@mafiabot host help` - Detailed Information about Hosting a game\n"
    response += "* `@mafiabot player help`- Detailed Information about Playing a game\n"
    response += "* `@mafiabot help`- This help command\n"
    return response
  playerHelp = () ->
    response = "Please use the following commands to specfiy advanced help\n"
    response += "* `@mafiabot host help` - Detailed Information about Hosting a game\n"
    response += "* `@mafiabot player help`- Detailed Information about Playing a game\n"
    response += "* `@mafiabot help`- This help command\n"
    return response
