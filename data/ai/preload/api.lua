-- Humongous proxy class
-- Created by Tom J Nowell 2010
-- Shard AI

require "hooks"
require "class"
require "aibase"

game = {}
	--game_engine
	
	-- prints 'message' to ingame chat console
	function game:SendToConsole(message)
		return game_engine:SendToConsole(message)
	end
	
	function game:Frame() -- returns int/game frame number
		if Spring ~= nil then
			return Spring.GetGameFrame() -- Spring Gadget API
		else
			return game_engine:Frame() -- Shard AI API
		end
	end
	
	function game:Test() -- debug
		return game_engine:Test()
	end
	
	function game:IsPaused() -- if the game is paused, returns true
		--
		return game_engine:IsPaused()
	end
	
	function game:GetTypeByName(typename) -- returns unittype
		--
		return game_engine:GetTypeByName(typename)
	end
	
	
	function game:ConfigFolderPath() -- returns string with path to the folder
		--
		return game_engine:ConfigFolderPath()
	end
	
	function game:ReadFile(filename) -- returns string with file contents
		--
		return game_engine:ReadFile(filename)
	end
	
	function game:FileExists(filename) -- returns boolean
		--
		return game_engine:FileExists(filename)
	end
	
	function game:GetTeamID() -- returns boolean
		--
		return game_engine:GetTeamID()
	end
	
	function game:GetEnemies()
		local has_enemies = game_engine:HasEnemies()
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
		end
	end
	
	function game:GetUnits()
		local fv = game_engine:GetUnits()
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f
	end
	
	function game:GetFriendlies()
		local has_friendlies = game_engine:HasFriendlies()
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
		end
	end
	
	
	function game:GameName() -- returns the shortname of this game
		--
		return game_engine:GameName()
	end
	
	function game:AddMarker(position,label) -- adds a marker
		--
		return game_engine:AddMarker(position,label)
	end
	
	
	function game:SendToContent(stringvar) -- returns a string passed from any lua gadgets
		--
		return game_engine:SendToContent(stringvar)
	end
	
	function game:GetResource(idx) --  returns a Resource object
		return game_engine:GetResource(idx)
	end
	
	function game:GetResourceCount() -- return the number of resources
		return game_engine:GetResourceCount()
	end
	
	function game:GetResourceByName(name) -- returns a Resource object, takes the name of the resource
		return game_engine:GetResourceByName(name)
	end
	
	function game:GetResources() -- returns a table of Resource objects, takes the name of the resource
		
		local rcount = game_engine:GetResourceCount()
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
		end
	end

map = {}

	-- function map:FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance)
	-- function map:CanBuildHere(unittype,position)
	-- function map:GetMapFeatures()
	-- function map:GetMapFeaturesAt(position,radius)
	-- function map:SpotCount()
	-- function map:GetSpot(idx)
	-- function map:GetMetalSpots()
	-- function map:MapDimensions()
	-- function map:MapName()
	-- function map:AverageWind()
	-- function map:MinimumWindSpeed()
	-- function map:MaximumWindSpeed()
	-- function map:TidalStrength()
	-- function map:MaximumHeight()
	-- function map:MinimumHeight()

-- ###################

	function map:FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance) -- returns Position
		--
		return game_engine:Map():FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance)
	end
	
	function map:CanBuildHere(unittype,position) -- returns boolean
		--
		return game_engine:Map():CanBuildHere(unittype,position)
	end
	
	function map:GetMapFeatures()
		local fv = game_engine:Map():GetMapFeatures()
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f
	end
	
	function map:GetMapFeaturesAt(position,radius)
		local m = game_engine:Map()
		local fv = m:GetMapFeaturesAt(position,radius)
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end 
		fv = nil
		return f
	end

	function map:SpotCount() -- returns the nubmer of metal spots
		local m = game_engine:Map()
		return m:SpotCount()
	end
	
	function map:GetSpot(idx) -- returns a Position for the given spot
		local m = game_engine:Map()
		return m:GetSpot(idx)
	end
	
	function map:GetMetalSpots() -- returns a table of spot positions
		--
		local m = game_engine:Map()
		local count = m:SpotCount()
		--local fv = game_engine:Map():GetMetalSpots()
		local f = {}
		local i = 0
		while i  < count do
			table.insert(f,m:GetSpot(i))
			i = i + 1
		end 
		--fv = nil
		return f
	end
	
	function map:MapDimensions() -- returns a Position holding the dimensions of the map
		local m = game_engine:Map()
		return m:MapDimensions()
	end
	
	function map:MapName() -- returns the name of this map
		local m = game_engine:Map()
		return m:MapName()
	end
	
	function map:AverageWind() -- returns (minwind+maxwind)/2
		local m = game_engine:Map()
		return m:AverageWind()
	end
	
	
	function map:MinimumWindSpeed() -- returns minimum windspeed
		local m = game_engine:Map()
		return m:MinimumWindSpeed()
	end
	
	function map:MaximumWindSpeed() -- returns maximum wind speed
		local m = game_engine:Map()
		return m:MaximumWindSpeed()
	end

	function map:MaximumHeight() -- returns maximum map height
		local m = game_engine:Map()
		return m:MaximumHeight()
	end

	function map:MinimumHeight() -- returns minimum map height
		local m = game_engine:Map()
		return m:MinimumHeight()
	end
	

	function map:TidalStrength() -- returns tidal strength
		local m = game_engine:Map()
		return m:TidalStrength()
	end
	
	game.map = map
--}
--[[
{,

IUnit/ engine unit objects
	int ID()
	int Team()
	std::string Name()

	bool IsAlive()

	bool IsCloaked()

	void Forget() // makes the interface forget about this unit and cleanup
	bool Forgotten() // for interface/debugging use
	
	IUnitType* Type()

	bool CanMove()
	bool CanDeploy()
	bool CanBuild()
	bool IsBeingBuilt()
	
	bool CanAssistBuilding(IUnit* unit)

	bool CanMoveWhenDeployed()
	bool CanFireWhenDeployed()
	bool CanBuildWhenDeployed()
	bool CanBuildWhenNotDeployed()

	void Stop()
	void Move(Position p)
	void MoveAndFire(Position p)

	bool Build(IUnitType* t)
	bool Build(std::string typeName)
	bool Build(std::string typeName, Position p)
	bool Build(IUnitType* t, Position p)

	bool AreaReclaim(Position p, double radius)
	bool Reclaim(IMapFeature* mapFeature)
	bool Reclaim(IUnit* unit)
	bool Attack(IUnit* unit)
	bool Repair(IUnit* unit)
	bool MorphInto(IUnitType* t)
	
	Position GetPosition()
	float GetHealth()
	float GetMaxHealth()

	int WeaponCount()
	float MaxWeaponsRange()

	bool CanBuild(IUnitType* t)

	SResourceTransfer GetResourceUsage(int idx)

	void ExecuteCustomCommand(int cmdId, std::vector<float> params_list, short options = 0, int timeOut = INT_MAX)

	UnitType{
		function Name() -- returns a string e.g. 'corcom'

		function CanDeploy() -- returns boolean
		function CanMoveWhenDeployed() -- returns boolean
		function CanFireWhenDeployed() -- returns boolean
		function CanBuildWhenDeployed() -- returns boolean
		function CanBuildWhenNotDeployed() -- returns boolean

		function Extractor() -- returns boolean
		
		function GetMaxHealth() -- returns a float
		
		function WeaponCount() -- returns integer
	},
	MapFeature {
		function ID()
		function Name()
		function GetPosition()
	},
	Position {
		x,y,z
	},

}

return infos]]--
