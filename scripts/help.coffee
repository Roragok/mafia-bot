#helpFunctions = require("./../src/helpers/help");


module.exports = (robot) ->

  # General Help
  robot.hear /@mafiabot help (.*)/i, (res) ->
    if res.match[1].toLowerCase() is "host"
      res.send(hostHelp())
    else if res.match[1].toLowerCase() is "player"
      res.send(playerHelp())
    else
      res.send(generalHelp())

  robot.hear /@mafiabot man (.*)/i, (res) ->
    if res.match[1].toLowerCase() is "host"
      res.send(hostHelp())
    else if res.match[1].toLowerCase() is "player"
      res.send(playerHelp())
    else
      res.send(generalHelp())

  robot.hear /@mafiabot player (.*)/i, (res) ->
    if res.match[1].toLowerCase() is "help"
      res.send(playerHelp())
    else if res.match[1].toLowerCase() is "man"
      res.send(playerHelp())

  generalHelp = () ->
    response = "Please use the following commands to specfiy advanced help\n"
    response += "* `@mafiabot host help` - Detailed Information about Hosting a game\n"
    response += "* `@mafiabot player help`- Detailed Information about Playing a game\n"
    response += "* `@mafiabot help`- This help command\n"
    return response

  hostHelp = () ->
    response = "The host of a Mafia game can use the following commands\n"
    response += "* `@mafiabot host` - This will take the current thread and create a signup\n"
    response += "* `@mafiabot startday [THREAD_ID]`- This will start first or next day of your game.  [THREAD_ID] is very important and must be the ID of the game the `host` command was excuted from\n"
    response += "* `@mafiabot kill playername`- This command must be excuted in the current day before you run the nextstartday command.  Must be excuted 1 time per player and is case sensitive.  This removes the player from the alive player list when the next `startday` command is excuted\n"
    return response


  playerHelp = () ->
    response = "Please use the following commands to specfiy advanced help\n"
    response += "* `@mafiabot host help` - Detailed Information about Hosting a game\n"
    response += "* `@mafiabot player help`- Detailed Information about Playing a game\n"
    response += "* `@mafiabot help`- This help command\n"
    return response
