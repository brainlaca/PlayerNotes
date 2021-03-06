### Player Notes

Player Notes is a World of Warcraft addon that allows you to set and manage notes on other player's characters. Notes are stored per realm so notes are shared across your characters on a realm. Notes can be set on any character name. The notes are simple and generic and are not tied to a friend, an ignored character, etc.

Player Notes is a fork of Character Notes. (https://github.com/Talryn/CharacterNotes)

Notes are displayed:

* When that character logs on
* When you do a /who on that character
* In unit tooltips
* **In LFG window tooltips (both leader and applicants)**
* Optionally as a hyperlink in chat
* From a command line interface
* From a GUI interface 

Notes can be set and managed:

* By right-clicking on **pretty much everything** where character names are displayed (unit frames, chat, guild window, lfg window, friends list, etc)
* From a command line interface
* From a GUI interface
* LDB launcher to bring up the GUI interface
* Minimap button to bring up the GUI interface 

Additional Features:

* LibAlt integration. See below. 
* ElvUI skin support.

Weakauras:

* Created a weakaura that indicates in the LFG window whether a note is set for:
    * The leader of the group in the group search view
    * The applicants in the applicant view

* Get it here: https://wago.io/OkztQKJ8H

Command-line options:

    /pn - Brings up the GUI
    /searchpn <search term> - Brings up the GUI. Optional search term allows filtering the list of notes.
    /setpn <name> <note> Sets a note for the character name specified.
    /delpn <name> Deletes the note for the character name specified.
    /getpn <name> Prints the note for the character name specified.
    /editpn <name> Brings up a window to edit the note for the name specified or your target if no name if specified. 

Player Notes can use LibAlts to get main-alt information. If no note is found for a character but one is found for the main of that character, it will display the note for the main.

Notes can be stored for characters not from your server but you'll need to use /editpn or the "Edit Note" menu item due to the spaces in the name (from the server name added at the end).

Note Links will add a hyperlink in chat next to any player name that you have set a note for. Clicking the "note" link will display the note in a tooltip.
