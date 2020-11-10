-- To display help use "run.lua -h"
--
--There are three ways to specify arguments for this program, interactively, by a settings file, or with command line (default is to use settings.ini)
--
-- To interactively specify the settings, run the run.lua script like so: "run.lua -i"
--
-- To specify a settings file, run the run.lua script like so: "run.lua -f <filename>"
--      Please look at the settings.ini file for an example on formating
-- 
-- To specify all parameters via command line, here is the argument order:
-- If you specify "-" for any parameters, the default will be used.
--           
--       run.lua -c <filename> <relocate> <outfile> <spacing> <minfill> <minvol> <minqual>
-- e.g.  run.lua -c models/example.obj false - 0.2 - 0.08 0.1
--
-- 
--
-- 
inspect = require "./inspect"

function getArgs(arg)
    local settings = {}
    --Set up the defaults, overwrite if necessary
    settings.filename = "models/example.obj"
    settings.outfile = "exampleRelocated.obj"
    settings.spacing = 0.1
    settings.minfill = 0.75
    settings.minvol  = 0.02
    settings.minqual = 0.1
    settings.relocate= false 
    
    --Use the  default settings.ini to override hardcoded defaults
    local settingfile = io.open("settings.lua","r")
    if settingfile~=nil then 
        io.close(settingfile) 
        settings = require ("settings")
        
        if settings.valid ~= true then --If it's improperly defined, restore defaults
            settings.filename = "models/example.obj"
            settings.outfile = "exampleRelocated.obj"
            settings.spacing = 0.1
            settings.minfill = 0.75
            settings.minvol  = 0.02
            settings.minqual = 0.1
            settings.relocate= false 
        end
    end    
    
    if arg[1] == "-i" then --interactively
        local valid = false
        while valid == false do
            print("Please specify the filename (.obj) to boxify:\n")
            settings.filename = io.read()
            local f = io.open(settings.filename,"r")
            if f == nil then 
                print("Sorry, " .. settings.filename .. " is not a valid file\n")
            else
                io.close(f)
                valid = true
            end
        end
        
        valid = false
        while valid == false do
            print("Please specify if you want your .obj file relocated to -1.5,-1.5,-1.5: <true/false>\n")
            settings.relocate = io.read()
            if settings.relocate == "true" then
                settings.relocate = true
                valid = true
                
                print("Please specify the filename of the relocated .obj to output\n")
                settings.outfile = io.read()
            elseif settings.relocate == "false" then
                settings.relocate = false
                settings.outfile = nil
                valid = true
            else
                print("Sorry, please enter 'true' or 'false'\n")
            end
        end
        
        valid = false
        while valid == false do
            print("Please specify the minimum percentage of your object all boxes must contain: \n(demical values like 0.1, between 0-1), 0.75 is the default\n")
            settings.minfill = io.read("*number")
            io.read()
            if settings.minfill <= 1 and settings.minfill >=0 then
                valid = true
            else
                print("You did not enter a number between 0 and 1, please enter a decimal number between 0-1 (e.g. 0.75)\n")
            end
        end
        
        valid = false
        while valid == false do
            print("Please specify the spacing between points(in minetest coords) to approximate your object: \n(demical values like 0.1, greater than 0), 0.1 is the default")
            print("This specifies how precisely to approximate your object, typically giving more fine grained results,\n smaller = more precise, also takes longer")
            settings.spacing = io.read("*number")
            io.read()
            if settings.spacing > 0 then
                valid = true
            else
                print("You did not enter a number greater than 0, please enter a decimal number greater than 0 (e.g. 0.1)\n")
            end
        end
        
        valid = false
        while valid == false do
            print("Please specify the minium volume of all boxes (in minetest coords): \n(demical values like 0.1, greater than 0), 0.02 is the default")
            print("For reference, the smallest volume of a 0.1 spaced grid is 0.1*0.1*0.1 = 0.001\n")
            settings.minvol = io.read("*number")
            io.read()
            if settings.minvol > 0 then
                valid = true
            else
                print("You did not enter a number greater than 0, please enter a decimal number greater than 0 (e.g. 0.02)\n")
            end
        end
        
        valid = false
        while valid == false do
            print("Advanced paramter: Minimum Quality\n")
            print("Please specify the minium percentage filled volume an object is allowed to grow into: \nDecimal number between 0-1 (e.g. 0.1)\n")
            settings.minqual = io.read("*number")
            io.read()
            if settings.minqual <= 1 and settings.minqual >=0  then
                valid = true
            else
                print("You did not enter a number between 0 and 1, please enter a decimal number between 0-1 (e.g. 0.1)\n")
            end
        end
        settings.valid = nil
        
        print("You entered: \n" .. inspect(settings))
        print("press <enter> to continue")
        io.read()
        require "./pause"
    
    elseif arg[1] == "-f" then --via settings file
        local settingfile = io.open(arg[2],"r")
        if settingfile~=nil then 
            settings = require (arg[2])
            if settings.valid ~= true then
                print(arg[2] .. " does not specify a valid settings file")
                os.exit()
            end
            io.close(settingfile) 
        else 
            print(arg[2] .. " does not specify an existing settings file")
            os.exit()
        end
    elseif arg[1] == "-c" then --via direct command line
        --run.lua c <filename> <relocate> <outfile> <spacing> <minfill> <minvol> <minqual>
        
        --filename should be given, but whatever
        if arg[2] ~= "-" and arg[3] ~= nil then
            settings.filename = arg[2]
            local f = io.open(settings.filename,"r")
            if f == nil then 
                print("arg2: Sorry, " .. settings.filename .. " is not a valid file\n")
                os.exit()
            end
        end
    
        if arg[3] ~=  "-" and arg[3] ~=nil then
            setting.relocate = arg[3]
            if settings.relocate == "true" then
                settings.relocate = true
            elseif settings.relocate == "false" then
                settings.relocate = false
            else
                print("Arg:3 Sorry, please enter 'true' or 'false' for 'relocation' \n")
                os.exit()
            end
        end
        
        if arg[4] ~=  "-" and arg[4] ~=nil then
            settings.outfile = arg[4] 
        else
            settings.outfile = "outfile.obj"
        end
        
        if arg[5] ~=  "-" and arg[5] ~=nil then
            settings.spacing = tonumber(arg[5])
            if settings.spacing <= 0 then
                print("arg5: You did not enter a number greater than 0 for spacing, please enter a decimal number greater than 0 (e.g. 0.1)\n")
                os.exit()
            end
        end
        
        if arg[6] ~=  "-" and arg[6] ~=nil then
            settings.minfill = tonumber(arg[6])
            if settings.minfill < 0  or settings.minfill > 1 then
                print("arg6: You did not enter a number between 0 and 1 for minimum box fill percentage, please enter a decimal number between 0-1 (e.g. 0.75)\n")
                os.exit()
            end
        end
        
        if arg[7] ~=  "-" and arg[7] ~=nil then
            settings.minvol = tonumber(arg[7])
            if settings.minvol <= 0 then
                print("arg7: You did not enter a number greater than 0 for minimum box volume, please enter a decimal number greater than 0 (e.g. 0.02)\n")
                os.exit()
            end
        end
        
        if arg[8] ~=  "-" and arg[8] ~=nil then
            settings.minqual = tonumber(arg[8])
            if settings.minqual < 0  or settings.minqual > 1 then
                print("arg8: You did not enter a number greater than 0 for minimum box volume, please enter a decimal number greater than 0 (e.g. 0.02)\n")
                os.exit()
            end
        end
    elseif arg[1] == "-h" then --help text display
        print( [[
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

There are three ways to specify arguments for this program:

  1. Interactively: "run.lua -i"
 
  2. User specified .lua settings file: "run.lua -f <path+filename.lua>"
      a. see settings.lua for example
     
  3. Via command line:
      a.     run.lua -c <filename> <relocate> <outfile> <spacing> <minfill> <minvol> <minqual>
      b. eg: run.lua -c models/example.obj false - 0.2 - 0.08 0.1
      c. If you specify "-" for any parameters, the default will be used.   
      
By default, the provided settings.lua is used. 
If that file is missing, internal defaults are used     
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------     
        ]])
        os.exit()
    end
    return settings
end


return getArgs
