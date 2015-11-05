-- Humongous proxy class
-- Created by Tom J Nowell 2010
-- Shard AI

require "hooks"
require "class"
require "aibase"


if Spring ~= nil then
	require "spring_lua/game"
else
	require "spring_native/game"
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
		local fv = game_engine:Map():GetMetalSpots()
		local count = m:SpotCount()
		local f = {}
		local i = 0
		while i  < count do
			table.insert( f, m:GetSpot(i) )
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
