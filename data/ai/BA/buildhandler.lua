require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BuildSiteHandler: " .. inStr)
	end
end

BuildSiteHandler = class(Module)

local sqrt = math.sqrt

function BuildSiteHandler:Name()
	return "BuildSiteHandler"
end

function BuildSiteHandler:internalName()
	return "buildsitehandler"
end

function BuildSiteHandler:Init()
	-- a convenient place for some other inits
	ai.factories = 0
	ai.maxFactoryLevel = 1
	ai.factoriesAtLevel = {}
	ai.outmodedFactoryID = {}
	local mapSize = map:MapDimensions()
	ai.maxElmosX = mapSize.x * 8
	ai.maxElmosZ = mapSize.z * 8
	ai.lvl1Mexes = 1 -- this way mexupgrading doesn't revert to taskqueuing before it has a chance to find mexes to upgrade

end

function BuildSiteHandler:CheckBuildPos(pos, unitTypeToBuild)
	if pos ~= nil then
		if (pos.x <= 0) or (pos.x > ai.maxElmosX) or (pos.z <= 0) or (pos.z > ai.maxElmosZ) then
			pos = nil
		end
	end
	-- sanity check: is it REALLY possible to build here?
	if pos ~= nil then
		local s = map:CanBuildHere(unitTypeToBuild, pos)
		if not s then
			pos = nil
		end
	end
	return pos
end

function BuildSiteHandler:ClosestBuildSpot(position, unitTypeToBuild, minimumDistance, attemptNumber)
	local minDistance = minimumDistance or 1
	local buildDistance = 2000
	local tmpAttemptNumber = attemptNumber or 0
	local pos = nil

	if tmpAttemptNumber > 0 then
		local searchAngle = (tmpAttemptNumber - 1) / 3 * math.pi
		local searchRadius = 2 * buildDistance / 3
		local searchPos = api.Position()
		searchPos.x = position.x + searchRadius * math.sin(searchAngle)
		searchPos.z = position.z + searchRadius * math.cos(searchAngle)
		searchPos.y = position.y
		pos = map:FindClosestBuildSite(unitTypeToBuild, searchPos, searchRadius / 2, minDistance)
	else
		pos = map:FindClosestBuildSite(unitTypeToBuild, position, buildDistance, minDistance)
	end

	-- check that we haven't got an offmap order, and that it's possible to build the unit there (just in case)
	pos = BuildSiteHandler:CheckBuildPos(pos, unitTypeToBuild)

	if pos == nil then
		-- first try increasing tmpAttemptNumber, up to 7
		-- should we do that?
		local tmpName = unitTypeToBuild:Name()
		local dontTryAlternatives = (dontTryAlternativePoints[tmpName] or 0) > 0
		if tmpAttemptNumber < 7 and not dontTryAlternatives then
			pos = BuildSiteHandler:ClosestBuildSpot(position, unitTypeToBuild, minimumDistance, tmpAttemptNumber + 1)
		else
			-- attempt 1 retry with reduced spacing, if allowed, and only use the 'central' position
			local reducedSpacing = unitsForNewPlacingLowOnSpace[unitTypeToBuild:Name()] or 0
			if reducedSpacing > 0 and reducedSpacing < minimumDistance and not dontTryAlternatives then
				pos = BuildSiteHandler:ClosestBuildSpot(position, unitTypeToBuild, reducedSpacing, nil)
			else
				game:SendToConsole("ClosestBuildSpot: can't find a position for "..unitTypeToBuild:Name())
			end
		end
	end

	return pos
end

function BuildSiteHandler:ClosestHighestLevelFactory(builder, maxDist)
	local bpos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local minDist = maxDist
	local maxLevel = ai.maxFactoryLevel
	EchoDebug(maxLevel .. " max factory level")
	local factory = nil
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		local uid = unit:ID()
		if unitTable[un].isBuilding and unitTable[un].buildOptions ~= nil and not ai.outmodedFactoryID[uid] then
			local level = unitTable[un].techLevel
			if level == maxLevel then
				local upos = unit:GetPosition()
				local dist = distance(bpos, upos)
				if dist < minDist then
					minDist = dist
					factory = unit
				end
			end
		end
	end
	return factory
end

function BuildSiteHandler:ClosestNanoTurret(builder, maxDist)
	local bpos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local minDist = maxDist
	local nano = nil
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		if un == "cornanotc" or un == "armnanotc" then
			local upos = unit:GetPosition()
			local dist = distance(bpos, upos)
			if dist < minDist then
				minDist = dist
				nano = unit
			end
		end
	end
	return nano
end

function BuildSiteHandler:ClosestBigEnergyPlant(builder, maxDist)
	local bpos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local minDist = maxDist
	local bige = nil
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		if bigEnergyPlant[un] then
			local upos = unit:GetPosition()
			local dist = distance(bpos, upos)
			if dist < minDist then
				minDist = dist
				bige = unit
			end
		end
	end
	return bige
end

function BuildSiteHandler:ClosestDefenseBuildSpot(builder, maxDist, utype, forShield)
	local bpos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local minDist = maxDist
	local maxLevel = ai.maxFactoryLevel
	EchoDebug(maxLevel .. " max factory level")
	local defendThis = nil
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		local uid = unit:ID()
		local good = false
		if unitTable[un].isBuilding and unitTable[un].buildOptions ~= nil and not ai.outmodedFactoryID[uid] then
			local level = unitTable[un].techLevel
			if level == maxLevel then
				good = true
			end
		elseif bigEnergyPlant[un] then
			good = true
		end
		if good then
			local upos = unit:GetPosition()
			if forShield then
				if self:PositionShielded(upos) then
					good = false
				end
			end
			if good then
				local dist = distance(bpos, upos)
				if dist < minDist then
					minDist = dist
					defendThis = unit
				end
			end
		end
	end
	local position
	if defendThis ~= nil then
		local defendPos = defendThis:GetPosition()
		position = self:ClosestBuildSpot(defendPos, utype, 10)
	end
	return position
end

function BuildSiteHandler:PositionShielded(position)
	local ownUnits = game:GetFriendlies()
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		if un == "corgate" or un == "armgate" then
			local upos = unit:GetPosition()
			local dist = distance(position, upos)
			if dist < 350 then
				return true
			end
		end
	end
	return false
end