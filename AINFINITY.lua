-- **************************************************************************************************
-- ** INFINITY AUTOFOCUS aInfinity.lua														  	   **
-- ** Alows you to store and restore focus settings at any time.							  	   **
-- ** NB : You still have to set the infinity focus by day for each lens and at each focal length. **
-- **************************************************************************************************

-- TODO : Get mor acurate focal lenght, optimize, set rotation clockwise or c/clockwise to optimize depending on the lens, maybe set a speed option, maybe a preset manager but for the time beeing you can use editor.lua

--local SAVEPATH = "ML/SCRIPTS/FOCUS/SETTINGS.LUA" -- not working yet

function table.save(t, f) -- printTable by @marcotrosi

	local file,err = io.open( f, "wb" )
	if err then 
		print("Error writting file")
		return err 
	end
	
	local function printTableHelper(obj, cnt)

		local cnt = cnt or 0

		if type(obj) == "table" then
			file:write("\n", string.rep("\t", cnt), "{\n")
			cnt = cnt + 1
			for k,v in pairs(obj) do
				if type(k) == "string" then
				   file:write(string.rep("\t",cnt), '["'..k..'"]', ' = ')
				end
				if type(k) == "number" then
				   file:write(string.rep("\t",cnt), "["..k.."]", " = ")
				end
				printTableHelper(v, cnt)
				file:write(",\n")
			end
			cnt = cnt-1
			file:write(string.rep("\t", cnt), "}")
			elseif type(obj) == "string" then
				file:write(string.format("%q", obj))
			else
				file:write(tostring(obj))
		end 
	end

	file:write("-- Focus Settings for AutoInfinity.lua, please don't modify if you don't know what you're doing.\n")
	file:write("-- Each lens can contain multiple focal lenght, values are steps that the autofocus motor has to go from soft limit to infinity.\n")
	file:write("return")
    printTableHelper(t)
	file:close()
end


function table:load()

	local settings = loadfile("ML/SCRIPTS/FOCUS/SETTINGS.LUA")
	if not settings then settings = function () return {[lens.name] = {},} end end -- create fake lens to initialize database
	return settings()								
end


function saveFile(settings, lens_focal, lens_steps)

	if settings[lens.name] then -- lens already exists
		if settings[lens.name][lens_focal] then -- setting already exists
			print("Setting already exists.\nOverride? (SET) / Press any other key to cancel.")
			if not(key.wait()==KEY.SET) then 
				print("Canceled")
				return settings
			else
				print("Overriding")
			end
		end
	else -- populate lens
		settings[lens.name]={}
	end
	
	settings[lens.name][lens_focal] = lens_steps
	table.save(settings, "ML/SCRIPTS/FOCUS/SETTINGS.LUA")
	print ("Set ! ("..lens_steps..") steps")
	return settings
end



function setInfinity() -- Main function to create a preset
    
	menu.close()
    console.show()
	
	if not lens.af then --should be picked up by menu settings, but leaving it just to be sure
        print("Please enable autofocus and restart the script")
    else  
		if not lv.running then lv.start() end --switch to LiveView													
		local settings = table.load()
		local i = 0
		
		local lens_focal = lens.focal_length -- failsafe if focal length can't be read
		if not(lens_focal) then lens_focal = "0" end
						   
		print "Setting infinity for:"
		print(lens.name)
		print("at focal length: "..lens.focal_length.."mm")
		
		print("Please wait...")
		while (lens.focus(-1,1,true,true))do -- Finding how many steps from infinity to soft limit
			i = i+1
		end
  
		local focal_length = lens.focal_length
		if not(focal_length) then -- failsafe for uncompatible lenses
			print("Couldn't read focal lenght, setting to zero. \nThis will still work but you only get one setting for this lens.")
			focal_length = 0 
		end																												   
		settings = saveFile(settings,focal_length, i)				  
	 
	end
	print "Press any key to exit."
	
    key.wait()
    console.hide()
end


function getInfinity() -- Main function to reach a preset
	
	menu.close()
    console.show()
	
	if not lens.af then
        print("Please enable autofocus and restart the script")
	else 
		local settings = table.load()  -- loading presets
		if next(settings) then --check if any settings exists

			if not lv.running then lv.start() end --switch to LiveView
			
			local lens_focal = lens.focal_length -- failsafe if focal length can't be read
			if not(lens_focal) then lens_focal = "0" end
			
			print "Getting infinity for:"
			print(lens.name)
			print("at focal length: "..lens_focal.."mm")
			
			local steps_to_infinity = settings[lens.name][lens_focal] -- getting preset from database
			if not steps_to_infinity then 
				print("Unable to find preset for this lens at this focal length, please use Set Infinity first.")
				return 
			end -- 
   
			print("Please wait...") --first push to soft limit
			while (lens.focus(-1,3,true,true))do
			end
   
			print("Do not touch the focus ring, this may take a while.") --then adjust
			lens.focus(steps_to_infinity,1,true,true)
			print("Focused to infinity!")
			print("You can now disable autofocus")
		else
			print "No preset found, use Set Infinity first!"
	 
		end
	end
	print "Press any key to exit."
	
	key.wait()
    console.hide()
end


keymenuSet = menu.new				   
{
	name   = "Set Infinity",
    help   = "Set an infinity preset for this lens & focal length",
	parent = "Focus",
	depends_on = DEPENDS_ON.AUTOFOCUS,
    select = function(this) task.create(setInfinity) end,
}
keymenuGet = menu.new
{
    name   = "Get Infinity",
    help   = "Retrieve an infinity preset for this lens & focal length",
	parent = "Focus",
	depends_on = DEPENDS_ON.AUTOFOCUS,
    select = function(this) task.create(getInfinity) end,
}
