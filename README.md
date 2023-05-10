# Description
We all know that feeling.
"Man I've been depleting Halls of Infusion left and right, must have been over 10 attempts today!"

KeyCount ... counts ... your mythic+ keys. This addon saves data about all your runs, including untimed and abandoned ones, so you'll finally know just how many times you attempted to time Brackenhide Hollow.

KeyCount also provides some basic stats that you can filter through, giving you valuable insights into your performance. This data is stored for all of your characters (but of course you can also just check one character).

This addon is still in beta development, but you can already download it from curse: https://www.curseforge.com/wow/addons/keycount

### Current features of KeyCount:
    - Effortless Data Tracking: Data recording starts when the timer for the dungeon starts. You can safely reload or walk in and out of the dungeon during the key.
    - Data: Current recorded data includes party members, affixes, deaths per party member and time to complete. This will be expanded in the future.
    - User-Friendly Interface: You can check your stats through chat commands (/kch for help) or through the ingame GUI: https://imgur.com/a/XZnrKlu Example overall success rate: https://imgur.com/a/zei0YX4

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
    - Add dropdown for filter keys
      - This would deprecate the logic required to use a dungeon abbreviation as key, but only for the gui
    - Add option tickboxes to show specific columns
      - Note, affixes, party, details stuff
    - Make GUI side scrollable if it gets too large?
    - Add role icons instead of text
    - If showing details stuff design it in a readable way

## Notes section
    - At the end of a failed run ask player for a note on that run (popup?)
    - Store note with the dungeon data
    - Add 'notes' column to gui (with mouseover or side scrollable)

## Data filter
    - Add role filter

## Data storage
    - Include details data about partymembers
      - Overall dps
      - Overall hps
      - Interrupts
