local map = {}
map.metal = shard_include("spring_lua/metal")

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
		return builderpos
		-- return game_engine:Map():FindClosestBuildSite(unittype,builderpos, searchradius, minimumdistance)
	end

	function map:CanBuildHere(unittype,position) -- returns boolean
		local newX, newY, newZ = Spring.Pos2BuildPos(unittype:ID(), position.x, position.y, position.z)
		local blocked = Spring.TestBuildOrder(unittype:ID(), newX, newY, newZ, 1) == 0
		-- Spring.Echo(unittype:Name(), newX, newY, newZ, blocked)
		return ( not blocked )
	end

	function map:GetMapFeatures()
		local fv = Spring.GetAllFeatures()
		if not fv then return {} end
		local f = {}
		for _, fID in pairs(fv) do
			f[#f+1] = Shard:shardify_feature(fID)
		end
		return f
	end

	function map:GetMapFeaturesAt(position,radius)
		local fv = Spring.GetFeaturesInSphere(position.x, position.y, position.z, radius)
		if not fv then return {} end
		local f = {}
		for _, fID in pairs(fv) do
			f[#f+1] = Shard:shardify_feature(fID)
		end
		return f
	end

	function map:SpotCount() -- returns the nubmer of metal spots
		return #self.metal.spots
	end

	function map:GetSpot(idx) -- returns a Position for the given spot
		return self.metal.spots[idx]
	end

	function map:GetMetalSpots() -- returns a table of spot positions
		local fv = self.metal.spots
		local count = self:SpotCount()
		local f = {}
		local i = 0
		while i  < count do
			table.insert( f, fv[i] )
			i = i + 1
		end
		return f
	end

	function map:MapDimensions() -- returns a Position holding the dimensions of the map
		return {
			x = Game.mapSizeX / 8,
			z = Game.mapSizeZ / 8,
			y = 0
		}
	end

	function map:MapName() -- returns the name of this map
		return Game.mapName
	end

	function map:AverageWind() -- returns (minwind+maxwind)/2
		return ( Game.windMin + (Game.windMax - Game.windMin)/2 )
	end


	function map:MinimumWindSpeed() -- returns minimum windspeed
		return Game.windMin
	end

	function map:MaximumWindSpeed() -- returns maximum wind speed
		return Game.windMax
	end

	function map:MaximumHeight() -- returns maximum map height
		local minHeight, maxHeight = Spring.GetGroundExtremes()
		return maxHeight
	end

	function map:MinimumHeight() -- returns minimum map height
		local minHeight, maxHeight = Spring.GetGroundExtremes()
		return minHeight
	end


	function map:TidalStrength() -- returns tidal strength
		return Game.tidal
	end

	-- game.map = map
return map