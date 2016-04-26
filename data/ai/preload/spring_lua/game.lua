local resourceIds = { "metal", "energy" }
local resourceKeyAliases = {
	currentLevel = "reserves",
	storage = "capacity",
	expense = "usage",
}

local function shardify_resource(luaResource)
	local shardResource = {}
	for key, value in pairs(luaResource) do
		local newKey = resourceKeyAliases[key] or key
		shardResource[newKey] = value
	end
	return shardResource
end

local game = {}
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
		return shardify_unittype(UnitDefNames[typename].id)
	end


	function game:ConfigFolderPath() -- returns string with path to the folder
		return "luarules/gadgets/ai/" .. self:GameName() .. "/"
		-- return game_engine:ConfigFolderPath()
	end

	function game:ReadFile(filename) -- returns string with file contents
		return VFS.LoadFile( filename )
	end

	function game:FileExists(filename) -- returns boolean
		return VFS.FileExists( filename )
	end

	function game:GetTeamID()
		return self.ai.id
		-- return Spring.GetMyTeamID()
	end

	function game:GetEnemies()
		return self.ai.enemyUnitIds
		-- local ev = self.ai.enemyUnitIds
		-- local e = {}
		-- for i =1, #ev do
		-- 	e[i] = ev[i]
		-- end
		-- return e
	end

	function game:GetUnits()
		return self.ai.ownUnitIds

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
		return self.ai.friendlyUnitIds

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
		return shardify_resource(Spring.GetTeamResources(self.ai.id, resourceIds[idx]))
		-- return false --game_engine:GetResource(idx)
	end

	function game:GetResourceCount() -- return the number of resources
		return 2 --game_engine:GetResourceCount()
	end

	function game:GetResourceByName(name) -- returns a Resource object, takes the name of the resource
		return shardify_resource(Spring.GetTeamResources(self.ai.id, name))
	end

	function game:GetUnitByID( unit_id ) -- returns a Shard unit when given an engine unit ID number
		return shardify_unit( unit_id )
	end

	function game:GetResources() -- returns a table of Resource objects, takes the name of the resource
		return { self:GetResource(1), self:GetResource(2) }

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

return game