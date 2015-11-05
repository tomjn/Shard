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