# Description
We all know that feeling.
"Man I've been depleting Siege of Boralus left and right, must have been over 10 attempts today!"

KeyCount stores data for all of your mythic+ runs, including untimed and abandoned (!) runs, so you'll finally know just how many times you attempted to time that specific key.

KeyCount also provides some basic stats that you can filter through, giving you valuable insights into your performance. This data is stored for all of the characters you run keys on.

This addon is still in beta development (the first stable release should be up soon), but you can already download it from curse: https://www.curseforge.com/wow/addons/keycount or wago: https://addons.wago.io/addons/keycount/versions?stability=beta

### Current features of KeyCount:
    - Effortless Data Tracking: Data recording starts when the timer for the dungeon starts, and ends when players leave the party, reset the dungeon, or finish the key. You can safely reload or walk in and out of the dungeon during the key.
    - Data: Current recorded data includes party members, affixes, dps/hps/deaths per party member, key time, key level, and more.
    - User-Friendly Interface: You can check your stats through chat commands (/kch for help) or through the ingame GUI: https://imgur.com/a/XZnrKlu Example overall success rate: https://imgur.com/a/zei0YX4
    - You can check data on every player that you have ran a key with. The addon provides statistics for each player per role and per season, all completely customisable. In addition, when you right-click a player (also works in LFG!) you can instantly see whether you have grouped with them before, what the results where, and click to open the GUI for that player.
    - Beta: each player is also given a score that correlates to the amount of times you've grouped with them. If you have a 100% success rate with someone, but only grouped once, they will have a score of ~60. If you are 10 out of 10 with them the score will be around 80. A current limitation here is that the success rate for high keys is not that high, so the score for all players tends to converge around 50 providing no valuable information.

### Current limitations:
    - If a player leaves the party, data recording is stopped and the key is marked as failed.
    - Only death count is recorded, not the cause of death or encounter.
    - No, this does not have the same capabilities as raider.io. It simply records basic stuff about your own runs.
    - Your latest data only shows up in the stats after you reload or relog.
    - There is no external database, so if you delete your SavedVariables folder your data is gone :(

# TODO
## Make sure addon does not reset in the following scenarios:
    - Other player leaves and rejoins party during active challenge mode
    - Other player leaves party but dungeon is still finished

## Do reset addon when:
    - Player logs out and into another character
      - Edge case: they need to send over mats so they log back in and continue the dungeon
    - Log out indefinitely

## Improve death recording
    - Register cause of death
    - Register encounter at time of death (boss/trash) with timestamp

## GUI
    - Add option tickboxes to show specific columns
      - Note, affixes, party, details stuff
    - Create custom sorting functions for each column (currently sorts by string value)
    - Add preference settings / options

## Notes section
    - At the end of a failed run ask player for a note on that run (popup?)
    - Store note with the dungeon data
    - Add 'notes' column to gui (with mouseover or side scrollable)

## Data filter
    - Enable multiple filters

## Player score
    - Improve algorithm to include best/average key level

## Bugs
    - Going out of dungeon disables the call to SetKeyFailed if someone leaves the group while you are outside (sometimes?)
    - Best key is not being stored correctly on player data (should only show completed key)
    - Player lookup screen doesn't filter by season
