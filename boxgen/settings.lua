local settings = {}
settings.valid = true
-----------------------------------Begin Settings--------------------------------------

    --This is the filename of the .obj file to be boxed

settings.filename = "models/example.obj"


    --If relocate is 'true', your .obj is automatically aligned so that the bottom left corner is at -1.5,-1.5,-1.5

settings.relocate = false 


    --If relocate is set to 'true', this is the name of the re-aligned obj file 

settings.outfile = "exampleRelocated.obj"


    --spacing is the distance between points used to approximate your object. 
    --Smaller values makes for more precise boxes, but can dramatically slow the processing. 
    --These values are in minetest coordinates, and it is best to skew on the larger side in general

settings.spacing = 0.1


    --minfill is a quality measure. It specifies what percentage of each box generated must actually be inside your .obj file. 
    --Setting this to 100 will result in many boxes, but will not protrude outside your object
    --Typically, if you want really fast (for minetest to run), decent boxing, a range from 0.60-0.80 is good.

settings.minfill = 0.75


    --minvol is how small the smallest box is allowed to be. For example, with a 0.1 spacing, the smallest box that can be generated is technically 
    --0.1*0.1*0.1 = 0.001. I typically recommend at least 0.02 to throw out frivolous (useless) boxes. 

settings.minvol  = 0.02


    --minqual is another quality measure, though it is a bit advanced. Essentially it says that a box should NOT grow in size when doing so would
    --add an area that is only a certain percentage of the object. For example, at 0.1 (10%), this means if I have a object like a pyramid:
    --       -
    --      - -
    --     -   -
    --    -     -
    --   ---------
    --
    -- and currently a given box is capturing everything but the very top tip of the pyramid, it will not grow to capture the top of the pyramid, because
    -- the area that would be adding in more than 90% air/empty. This occurs even if a given box is still well within the minfill percentage bounds (say 90% filled at this point)
    -- minqual, therefore typically will help you generate boxes that don't "reach" for very small protrutions. I reccomend playing with the value if you don't like the results 
    -- that minvol can give you alone. Typically, I don't personally raise this much past 0.2, but feel free to play with it!

settings.minqual = 0.1


-----------------------------------End Settings-------------------------------------
return settings
