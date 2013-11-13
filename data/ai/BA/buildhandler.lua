require "unitlists"
require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BuildSiteHandler: " .. inStr)
	end
end

BuildSiteHandler = class(Module)

local sqrt = math.sqrt

local mexUnitType

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
	ai.factoryLocationsAtLevel = {}
	ai.outmodedFactoryID = {}
	local mapSize = map:MapDimensions()
	ai.maxElmosX = mapSize.x * 8
	ai.maxElmosZ = mapSize.z * 8
	ai.lvl1Mexes = 1 -- this way mexupgrading doesn't revert to taskqueuing before it has a chance to find mexes to upgrade
	mexUnitType = game:GetTypeByName("cormex")
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

function BuildSiteHandler:ClosestBuildSpot(builder, position, unitTypeToBuild, minimumDistance, attemptNumber)
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
	pos = self:CheckBuildPos(pos, unitTypeToBuild)

	--[[
	if pos ~= nil then
		-- don't build on top of free metal spots
		local spot, uw, dist = ai.maphandler:ClosestFreeSpot(mexUnitType, builder, position)
		if spot ~= nil and dist ~= nil then
			if dist < 100 then
				pos = nil
			end
		end
	end
	]]--

	--[[
	if pos ~= nil then
		-- don't build where the builder can't go
		if not ai.maphandler:UnitCanGoHere(builder, pos) then
			EchoDebug("builder can't go there: " .. pos.x .. "," .. pos.z)
			pos = nil
		end
	end
	]]--

	if pos == nil then
		-- first try increasing tmpAttemptNumber, up to 7
		-- should we do that?
		local tmpName = unitTypeToBuild:Name()
		local dontTryAlternatives = (dontTryAlternativePoints[tmpName] or 0) > 0
		if tmpAttemptNumber < 7 and not dontTryAlternatives then
			pos = self:ClosestBuildSpot(builder, position, unitTypeToBuild, minimumDistance, tmpAttemptNumber + 1)
		else
			-- attempt 1 retry with reduced spacing, if allowed, and only use the 'central' position
			local reducedSpacing = unitsForNewPlacingLowOnSpace[unitTypeToBuild:Name()] or 0
			if reducedSpacing > 0 and reducedSpacing < minimumDistance and not dontTryAlternatives then
				pos = self:ClosestBuildSpot(builder, position, unitTypeToBuild, reducedSpacing, nil)
			else
				pos = nil
				EchoDebug("ClosestBuildSpot: can't find a position for "..unitTypeToBuild:Name())
			end
		end
	end

	return pos
end

function BuildSiteHandler:ClosestHighestLevelFactory(builder, maxDist)
	local bpos = builder:GetPosition()
	local minDist = maxDist
	local maxLevel = ai.maxFactoryLevel
	EchoDebug(maxLevel .. " max factory level")
	local factoryPos = nil
	for i, location in pairs(ai.factoryLocationsAtLevel[maxLevel]) do
		if not ai.outmodedFactoryID[location.uid] then
			local dist = distance(bpos, location.position)
			if dist < minDist then
				minDist = dist
				factoryPos = location.position
			end
		end
	end
	return factoryPos
end

function BuildSiteHandler:ClosestNanoTurret(builder, maxDist)
	local bpos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local minDist = maxDist
	local nano = nil
	for i, unit in pairs(ownUnits) do
		local un = unit:Name()
		if nanoTurretList[un] then
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

function BuildSiteHandler:DontBuildHere(position, range)
	table.insert(self.seriouslyDont, {position = position, range = range})
end