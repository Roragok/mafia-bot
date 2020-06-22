# helpFunctions = require("./../src/helpers/help");


module.exports = (robot) ->

  # General Help
  robot.hear /@mafiabot help/i, (res) ->
    res.send(help())

  help = () ->
    response = "[Commands]
    (https://github.com/Roragok/mafia-bot/blob/master/README.md#command--list)
    \n"
    return response
