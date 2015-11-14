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
		-- needs spring gadget implementation, perhaps https://github.com/spring1944/spring1944/blob/master/LuaRules/Gadgets/craig/buildsite.lua ?
		return nil
		-- return game_engine:Map():FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance)
	end

	function map:CanBuildHere(unittype,position) -- returns boolean
		local unitName = unittype:Name()
		local def = UnitDefNames[unitName]
		local newX, newY, newZ = Spring.Pos2BuildPos(def.id, position.x, position.y, position.z)

		local blocked = Spring.TestBuildOrder(def.id, newX, newY, newZ, 1) == 0
		return ( not blocked )
	end

	function map:GetMapFeatures()
		return nil

		--[[local fv = game_engine:Map():GetMapFeatures()
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f]]--
	end

	function map:GetMapFeaturesAt(position,radius)
		return nil

		--[[local m = game_engine:Map()
		local fv = m:GetMapFeaturesAt(position,radius)
		local f = {}
		local i = 0
		while i  < fv:size() do
			table.insert(f,fv[i])
			i = i + 1
		end
		fv = nil
		return f]]--
	end

	function map:SpotCount() -- returns the nubmer of metal spots
		return 0

		--local m = game_engine:Map()
		--return m:SpotCount()
	end

	function map:GetSpot(idx) -- returns a Position for the given spot
		return nil

		--local m = game_engine:Map()
		--return m:GetSpot(idx)
	end

	function map:GetMetalSpots() -- returns a table of spot positions
		return nil

		--[[
		local m = game_engine:Map()
		local fv = game_engine:Map():GetMetalSpots()
		local count = m:SpotCount()
		local f = {}
		local i = 0
		while i  < count do
			table.insert( f, m:GetSpot(i) )
			i = i + 1
		end
		fv = nil
		return f
		]]--
	end

	function map:MapDimensions() -- returns a Position holding the dimensions of the map
		return {
			x = Game.mapX,
			y = Game.mapY,
			z = 0
		}
	end

	function map:MapName() -- returns the name of this map
		return Game.mapName
	end

	function map:AverageWind() -- returns (minwind+maxwind)/2
		return ( Game.windMin + (Game.windMax - game.windMin)/2 )
	end


	function map:MinimumWindSpeed() -- returns minimum windspeed
		return Game.windMin
	end

	function map:MaximumWindSpeed() -- returns maximum wind speed
		return Game.windMax
	end

	function map:MaximumHeight() -- returns maximum map height
		return 0

		-- local m = game_engine:Map()
		-- return m:MaximumHeight()
	end

	function map:MinimumHeight() -- returns minimum map height
		return 0

		-- local m = game_engine:Map()
		-- return m:MinimumHeight()
	end


	function map:TidalStrength() -- returns tidal strength
		return Game.tidal
	end

	game.map = map