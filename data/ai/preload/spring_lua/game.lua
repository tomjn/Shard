game = {}
	--game_engine

	-- prints 'message' to ingame chat console
	function game:SendToConsole(message)
		Spring.Echo( message )
		return true
	end

	function game:Frame() -- returns int/game frame number
		return Spring.GetGameFrame() -- Spring Gadget API
	end

	function game:Test() -- debug
		Spring.Echo( "Testing API" )
		return true
	end

	function game:IsPaused() -- if the game is paused, returns true
		local _, _, paused = Spring.GetGameSpeed()
		return paused
	end

	function game:GetTypeByName(typename) -- returns unittype
		--
		return nil
		-- return game_engine:GetTypeByName(typename)
	end


	function game:ConfigFolderPath() -- returns string with path to the folder
		--
		return "" --
		-- return game_engine:ConfigFolderPath()
	end

	function game:ReadFile(filename) -- returns string with file contents
		return VFS.LoadFile( filename )
	end

	function game:FileExists(filename) -- returns boolean
		return VFS.FileExists( filename )
	end

	function game:GetTeamID() -- returns boolean
		return Spring.GetMyTeamID()
	end

	function game:GetEnemies()
		return nil

		--[[local has_enemies = game_engine:HasEnemies()
		if has_enemies ~= true then
			return nil
		else
			local ev = game_engine:GetEnemies()
			local e = {}
			local i = 0
			while i  < ev:size() do
				table.insert(e,ev[i])
				i = i + 1
			end
			ev = nil
			return e
		end]]--
	end

	function game:GetUnits()
		return nil

		--[[local fv = game_engine:GetUnits()
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f]]--
	end

	function game:GetFriendlies()
		return nil

		--[[local has_friendlies = game_engine:HasFriendlies()
		if has_friendlies ~= true then
			return nil
		else
			local fv = game_engine:GetFriendlies()
			local f = {}
			local i = 0
			while i  < fv:size() do
				table.insert(f,fv[i])
				i = i + 1
			end
			fv = nil
			return f
		end]]--
	end

	function game:GameName() -- returns the shortname of this game
		--
		return Game.gameShortName
	end

	function game:AddMarker(position,label) -- adds a marker
		Spring.MarkerAddPoint( position.x, position.y, position.z, label )
		return true
	end

	function game:SendToContent(stringvar) -- returns a string passed from any lua gadgets
		-- doesn't make a lot of sense if we're already in the lua environment, needs discussin
		return false --game_engine:SendToContent(stringvar)
	end

	function game:GetResource(idx) --  returns a Resource object
		return false --game_engine:GetResource(idx)
	end

	function game:GetResourceCount() -- return the number of resources
		return 2 --game_engine:GetResourceCount()
	end

	function game:GetResourceByName(name) -- returns a Resource object, takes the name of the resource
		return "" --game_engine:GetResourceByName(name)
	end

	function game:GetUnitByID( unit_id ) -- returns a Shard unit when given an engine unit ID number
		return nil --game_engine:getUnitByID( unit_id )
	end

	function game:GetResources() -- returns a table of Resource objects, takes the name of the resource
		return {}

		--[[local rcount = game_engine:GetResourceCount()
		if(rcount > 0) then

			local resources = {}

			for i = 0,rcount do
				local res = game:GetResource(i)
				if res.name ~= "" then
					resources[res.name] = res
				end
			end
			return resources
		else
			return nil
		end]]--
	end

