# Mafia Bot
The goal of this project was to have a bot to help host and facilitate [Mafia Games](https://en.wikipedia.org/wiki/Mafia_(party_game)). A light weight discourse integration of [hubot](https://hubot.github.com/).

Runs on [NAMafia](https://namafia.com).

## What does it do?

It facilitates game creation and vote management.  A host can list a game for players (other forum memebers) to sign up.  The host can than start the game when he has enough players.  The bot will manage the game into phases broken down by "Day" or 1 interactive cycle.  The bot is unaware of the night phase and roles/actions each player performs.  It can only count votes at this juncture.

##  Command  List

All commands must be prefaced by `@mafiabot`


### Host Commands

| Command | Parameters | Description |
| :------------- | :------------- | :------------- |
| host       |     | Creates a signup in the current thread |
| autolock | | Enables the game/day to have autolocking.  Day threads inherit this setting from the signup thread |
| unlock | THREAD_ID | The host can unlock a day thread by PMing the unlock command with the thread id of the current day  i.e. `@mafiabot unlock 5589` |
| add | `playername`| This command allows a host to add a player to the signlist |
| remove | `playername`| This command allows a host to remove a player from the signlist |
| startday | SIGNUP_THREAD_ID | Starts first or next day of your game.  `SIGNUP_THREAD_ID` is very important and must be the ID of the game the `host` command was excuted from|
| end | `winning faction`| i.e (town, mafia, third). Allows a host to result a game.  Closes the game and display a winner internally.
| kill | playername | Kills `playername` This command must be executed in the current day before you run the next startday command.  Must be excuted 1 time per player and is case sensitive.  This removes the player from the alive player list when the next `startday` command is executed.|
| zeus| `playername` | Mimics kill but with flavor text ingame|
| help | | A link to this readme |

### General Commands

| Command | Parameters | Description |
| :------------- | :------------- | :------------- |
| slist | | Lists all signed players for a hosted game thread. |
| sign | | Sign you up for a hosted game. alias `.s` |
| unsign | | Unsigns you from a hosted game |
| lynch | target | Casts your lynch vote on `target`. Where target is an alive player in the game.  Optionally you can set `target` to `noylnch` to vote for no lynch . alias `vote`|
| unlynch | | Removes your current lynch target |
| vc | | Shows the current count of votes. alias `votecount` |
| help | | A link to this readme |
