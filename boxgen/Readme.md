# Boxgen

## A Lua-based auto-matic collision-box generator

* Accepts water-tight obj files
* You specify the accuracy and minimum size boxes generated
* Automatically breaks obj files larger than 3 in any axis direction into multiple nodes
* Outputs information in a friendly minetest format for use with an extended register function for such entities

## To-Be-Completed

1. Minetest Collision box output formated file export(.box)
2. Minetest Supporting Mod with new register .box node function
    * Simply hand the register function normal node def. and the .box filename/location instead of a collision box
    * Implement an on_place function that checks for available space, and will place nodes in correct positions, and tell user when it fails why it fails
    * Implement a rotate function that checks for available space, and will reorganize nodes into correct positions, and tell user when it fails why it fails
    * Implement a dig function that will remove all associated nodes and return the single node to inventory
3. Improve/add new boxing algorithm to have the option for randomized starting points
4. Provide Tutorial Video
5. Provide Tutorial Text
6. Provide Tutorial on Using Meshlab to make a simplified watertight mesh for making decent approximations. 
7. Release mod using this toolset 


## Current Basic Tutorial

1. Download the files in this folder (or all of story_npc)
2. make sure you have lua installed on your computer, if you are on windows, I reccomend "Lua for Windows": https://code.google.com/archive/p/luaforwindows/downloads
3. Run the boxgen/run.lua to make sure your lua installation is working
4. You will see that run.lua exported some html files (or overwrote them), feel free to open them in a browser and view the generated boxes
5. To play with the settings, edit the parameters at the top of run.lua
6. Feel free to test with your own .obj files, but remember that they must be watertight! Most objs are NOT watertight by default.
   6a. If you are wanting to test further at this point with nono-watertight meshes, I reccomend using Meshlab: https://www.meshlab.net/
       You can import .objs and eport .objs from it, and it has "remeshing" filters that allow you to make a watertight approximation of your
       object (use marching cubes, and then "simplify" to have like 350 triangles/faces). The result will look rough compared to your original, 
       but that is more than okay! Remember, we are approximating your object with boxes. Boxes. 
       So you don't need a super detailed representation to run through this program. Feel free to open issues with story_npc if you find the need!
