# MAFIA BOT

The bot that does mafia things on [NAMafia](https://namafia.com)



##  Command  List

All commands must be prefaced by `@mafiabot`

| Command | Parameters | Description |
| :------------- | :------------- | :------------- |
| host       |     | Creates a signup in the current thread |
| startday | THREAD_ID | Starts first or next day of your game.  `THREAD_ID` is very important and must be the ID of the game the `host` command was excuted from|
| kill | playername | Kills `playername` This command must be executed in the current day before you run the next startday command.  Must be excuted 1 time per player and is case sensitive.  This removes the player from the alive player list when the next `startday` command is excuted|
| sign | | Sign you up for a hosted game |
| unsign | | Unsigns you from a hosted game |
| slist | | Lists all signed players for a hosted game thread. |
| lynch | target | Casts your lynch vote on `target`. Where target is an alive player in the game.  Optionally you can set `target` to `noylnch` to vote for no lynch |
| unlynch | | Removes your current lynch target |
| vc | | Shows the current count of votes. |
