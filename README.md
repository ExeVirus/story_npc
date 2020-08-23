# story_npc
In-Game Programable NPC's


[Picture]

## Overview

Story NPC allows you to fill your world with Dialog, interacions, story telling, quests, trading, and much more. 

Everything is accomplished through the story_npc:wand, Which allows you to edit a given NPC with left click, create a new NPC with right click, 
or copy an NPC with shift-left (copy) and shift-right (paste) click. 

The mod has a built-in guide called story_npc:tome. It covers every feature in the MOD and should answer 99.9% of your questions. It also stores 
player quest information. 

### Technical Overview

So everything works with formspecs for editing and displaying interactions. The real innovation of this mod, though, is the event subsystem. 
Events are simply a grouping of two things: triggers, and actions. When all triggers are met, all actions occur. Simple, right?

Triggers can include: player within a certain range, seeing a player, being interacted with, having a certain item in inventory, being a certain time of day, etc.
Actions can include: giving you an item, dialog, trading, shopping, giving you a quest, etc. 

The most important trigger and actions are *flags* These are simply a player specific flag that is given to a player. 
You can trigger events if they have the flag, or if they dont. You can give a player any flag with any event, or remove any flag with any event. 

Why are flags so useful, lets go down to our example:


## Example Basic NPC:

Say you want to have a chain of dialog with an npc. The first time you talk to them, they should greet you and tell you about themselves. 
The second time they should greet you based on the time of day and say "good morning/good evening/good afternoon/you should be asleep!"

The events for this NPC would be as follows:
```
Event 1:
     Triggers:
        1. Player interaction
        2. No "first_greeting" flag set for player.
     Actions:
        1. Dialog: "Hello my name is Edward, but you can call me Ed. Hope to see you around!"
        2. Set player flag "first_greeting"
Event 2:
     Triggers:
        1. Player interaction
        2. "first_greeting" flag set for player.
        3. Time of day is between 7:00am-12:00pm
     Actions:
        1. Dialog: "Good morning, [player_name], Hope you are enjoying this fine day!"
Event 2:
     Triggers:
        1. Player interaction
        2. "first_greeting" flag set for player.
        3. Time of day is between 12:00pm-5:00pm
     Actions:
        1. Dialog: "Good afternoon, [player_name], Hope you're stayin' out of trouble!"
Event 3: Etc.
```
As you can see, a given player will only see the first greeting once, and then get a time specific greeting thereafter 
because they will have the *first_greeting* flag set. 

Also, this may seem quite wordy and hard to program, but I assure you that formspecs make programming this much easier:

[Event 1 example]

### Other non-usage question FAQ's:

1. Can I use your mod? 
> It's MIT license, meaning you can use it wherever you want. Enjoy!

2. I want to add a new kind of trigger/aciton/idea to your mod.
> Okay, make a pull request and we can see if it makes sense to merge

3. You didn't support translations yet... 
> Sorry I'm a fledgling minetest modder, feel free to help me 
> with a pull request example or reach out to me on the unofficial MT discord

4. This is a great mod! How do I show my appreciation?
> 1. Use it
> 2. Write a positive review on the Minetest Content DB so others can find it more easily
> 3. Make a game or server or map using it and share! I love minetest and want more fun things to built in it!
