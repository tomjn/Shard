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
	

	function map:TidalStrength() -- returns tidal strength
		local m = game_engine:Map()
		return m:TidalStrength()
	end
	
	game.map = map
--}
--[[
{,
	Unit = {
		function ID()-- returns this units ID
		function Name() -- returns this units internal name e.g. corcom
		function IsAlive()
		
		function IsCloaked()
		
		function Type() -- returns a unittype

		function CanMove() -- returns boolean
		function CanDeploy() -- returns boolean
		function CanBuild() -- returns boolean

		function CanMorph() -- returns boolean
		
		function CanAssistBuilding(Unit) -- returns boolean

		function CanMoveWhenDeployed() -- returns boolean
		function CanFireWhenDeployed() -- returns boolean
		function CanBuildWhenDeployed() -- returns boolean
		function CanBuildWhenNotDeployed() -- returns boolean

		function Stop()
		function Move(Position)
		function MoveAndFire(Position)

		-- the Build methods now return true if it worked, false if the command was bad
		function Build(UnitType)
		function Build(typeName)
		function Build(typeName, Position)
		function Build(UnitType, Position)
		
		function Reclaim(unit)
		function Reclaim(mapFeature)
		function Attack(unit)
		function Repair(unit)
		
		function GetPosition() -- returns a Position
		function GetHealth() -- returns a float
		function GetMaxHealth() -- returns a float
		
		function WeaponCount() -- returns integer
		function MaxWeaponsRange() -- float
		
		function CanBuild(unitType) -- boolean
	},
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
