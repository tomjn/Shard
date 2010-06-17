-- Humongous proxy class
-- Created by Tom J Nowell 2010
-- Shard AI

require "class"
require "aibase"

game = {}
	--game_engine
	
	-- prints 'message' to ingame chat console
	function game:SendToConsole(message)
		return game_engine:SendToConsole(message)
	end
	
	function game:Frame() -- returns int/game frame number
		--
		return game_engine:Frame()
	end
	
	function game:Test() -- debug
		return game_engine:Test()
	end
	
	function game:IsPaused() -- if the game is paused, returns true
		--
		return game_engine:IsPaused()
	end
	
	function game:FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance) -- returns Position
		--
		return game_engine:FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance)
	end
	
	function game:CanBuildHere(unittype,position) -- returns boolean
		--
		return game_engine:CanBuildHere(unittype,position)
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
	
	function game:ExecuteFile(filename) -- executes given file (use require include or dofile when possible) DEPRECATED
		--
		return game_engine:ExecuteFile(filename)
	end
	
	function game:FileExists(filename) -- returns boolean
		--
		return game_engine:FileExists(filename)
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
	
	function game:GetMapFeatures()
		local fv = game_engine:GetMapFeatures()
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f
	end
	
	function game:GetMapFeatures(position,radius)
		local fv = game_engine:GetMapFeatures(position,radius)
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end 
		fv = nil
		return f
	end
	
	
	function game:SpotCount() -- returns the nubmer of metal spots
		--
		return game_engine:SpotCount()
	end
	
	function game:GetSpot(idx) -- returns a Position for the given spot
		--
		return game_engine:GetSpot(idx)
	end
	
	function game:GetMetalSpots() -- returns a table of spot positions
		--
		local count = game_engine:SpotCount()
		--local fv = game_engine:GetMetalSpots()
		local f = {}
		local i = 0
		while i  < count do
			table.insert(f,game_engine:GetSpot(i))
			i = i + 1
		end 
		--fv = nil
		return f
	end
	
	function game:MapDimensions() -- returns a Position holding the dimensions of the map
		--
		return game_engine:MapDimensions()
	end
	
	
	function game:GameName() -- returns the shortname of this game
		--
		return game_engine:GameName()
	end
	
	function game:MapName() -- returns the name of this map
		--
		return game_engine:MapName()
	end
	
	
	function game:AddMarker(position,label) -- adds a marker
		--
		return game_engine:AddMarker(position,label)
	end
	
	
	function game:SendToContent(stringvar) -- returns a string passed from any lua gadgets
		--
		return game_engine:SendToContent(stringvar)
	end
	
	
	function game:AverageWind() -- returns (minwind+maxwind)/2
		--
		return game_engine:AverageWind()
	end
	
	
	function game:MinimumWindSpeed() -- returns minimum windspeed
		--
		return game_engine:MinimumWindSpeed()
	end
	
	function game:MaximumWindSpeed() -- returns maximum wind speed
		--
		return game_engine:MaximumWindSpeed()
	end
	

	function game:TidalStrength() -- returns tidal strength
		return game_engine:TidalStrength()
	end
	
	function game:GetResource(idx) --  returns a Resource object
		return game_engine:GetResource(idx)
	end
	
	function game:GetResourceCount() -- return the number of resources
		return game_engine:GetResourceCount()
	end
	
	function game:GetResource(name) -- returns a Resource object, takes the name of the resource
		return game_engine:GetResource(name)
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
