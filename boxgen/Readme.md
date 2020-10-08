# Boxgen

## A Lua-based auto-matic collision-box generator

* Accepts water-tight obj files
* You specify the accuracy and minimum size boxes generated
* Automatically breaks obj files larger than 3 in any axis direction into multiple nodes
* Outputs information in a friendly minetest format for use with an extended register function for such entities

## To-Be-Completed

0. Fix Autoscaling grid issue for skew.
1. Minetest Collision box output formated file export(.box)
2. Code cleanup and encapsulation (i.e. break up functions from calling lua file)
3. Minetest Supporting Mod with new register .box node function
    * Simply hand the register function normal node def. and the .box filename/location instead of a collision box
    * Implement an on_place function that checks for available space, and will place nodes in correct positions, and tell user when it fails why it fails
    * Implement a rotate function that checks for available space, and will reorganize nodes into correct positions, and tell user when it fails why it fails
    * Implement a dig function that will remove all associated nodes and return the single node to inventory
4. Improve/add new boxing algorithm to have the option for randomized starting points
5. Improve/add new boxing alrogithm to use number of filled voxels^2/total possible voxels rather than number of filled voxels. Will grow "better"
6. Provide Tutorial Video
7. Provide Tutorial Text
8. Provide Tutorial on Using Meshlab to make a simplified watertight mesh for making decent approximations. 
9. Release mod using this toolset 