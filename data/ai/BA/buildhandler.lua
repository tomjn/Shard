require "unitlists"
require "unittable"

local DebugEnabled = false
local debugPlotBuildFile

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("BuildSiteHandler: " .. inStr)
	end
end

local function PlotSquareDebug(x, z, size, label)
	if DebugEnabled then
		x = math.ceil(x)
		z = math.ceil(z)
		size = math.ceil(size)
		-- if debugSquares[x .. "  " .. z .. " " .. size] == nil then
			if label == nil then label = "nil" end
			local string = x .. " " .. z .. " " .. size .. " " .. label .. "\n"
			debugPlotBuildFile:write(string)
			-- debugSquares[x .. "  " .. z .. " " .. size] = true
		-- end
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
	ai.maxFactoryLevel = 0
	ai.factoriesAtLevel = {}
	ai.outmodedFactoryID = {}
	local mapSize = map:MapDimensions()
	ai.maxElmosX = mapSize.x * 8
	ai.maxElmosZ = mapSize.z * 8
	ai.nameCount = {}
	ai.nameCountFinished = {}
	ai.lastNameCreated = {}
	ai.lastNameFinished = {}
	ai.lastNameDead = {}
	ai.mexCount = 0
	ai.conCount = 0
	ai.combatCount = 0
	ai.battleCount = 0
	ai.breakthroughCount = 0
	ai.reclaimerCount = 0
	ai.lvl1Mexes = 1 -- this way mexupgrading doesn't revert to taskqueuing before it has a chance to find mexes to upgrade
	self.seriouslyDont = {}
	self:DontBuildOnMetalOrGeoSpots()
end

function BuildSiteHandler:CheckBuildPos(pos, unitTypeToBuild, builder, originalPosition)
	-- make sure it's on the map
	if pos ~= nil then
		if unitTable[unitTypeToBuild:Name()].buildOptions then
			-- don't build factories too close to south map edge because they face south
			if (pos.x <= 0) or (pos.x > ai.maxElmosX) or (pos.z <= 0) or (pos.z > ai.maxElmosZ - 50) then
				EchoDebug("bad position: " .. pos.x .. ", " .. pos.z)
				pos = nil
			end
		else
			if (pos.x <= 0) or (pos.x > ai.maxElmosX) or (pos.z <= 0) or (pos.z > ai.maxElmosZ) then
				EchoDebug("bad position: " .. pos.x .. ", " .. pos.z)
				pos = nil
			end
		end
	end
	-- sanity check: is it REALLY possible to build here?
	if pos ~= nil then
		local s = map:CanBuildHere(unitTypeToBuild, pos)
		if not s then
			EchoDebug("cannot build " .. unitTypeToBuild:Name() .. " here: " .. pos.x .. ", " .. pos.z)
			pos = nil
		end
	end
	-- don't build where you shouldn't (metal spots, factory lanes)
	if pos ~= nil then
		for i, square in pairs(self.seriouslyDont) do
			local dist = distance(square.position, pos)
			if dist <= square.size then
				EchoDebug("build position " .. pos.x .. ", " .. pos.z .. " is " .. dist .. " away, zone is " .. square.size)
				pos = nil
				break
			end
		end
	end
	-- don't build where the builder can't go
	if pos ~= nil then
		if not ai.maphandler:UnitCanGoHere(builder, pos) then
			EchoDebug(builder:Name() .. " can't go there: " .. pos.x .. "," .. pos.z)
			pos = nil
		end
	end
	if pos ~= nil then
		local uname = unitTypeToBuild:Name()
		if nanoTurretList[uname] then
			-- don't build nanos too far away from factory
			local dist = distance(originalPosition, pos)
			EchoDebug("nano distance: " .. dist)
			if dist > 400 then
				EchoDebug("nano too far from factory")
				pos = nil
			end
		elseif bigPlasmaList[uname] or littlePlasmaList[uname] or nukeList[uname] then
			-- don't build bombarding units outside of bombard positions
			local b = ai.targethandler:IsBombardPosition(pos, uname)
			if not b then
				EchoDebug("bombard not in bombard position")
				pos = nil
			end
		end
	end
	return pos
end

function BuildSiteHandler:GetBuildSpacing(unitTypeToBuild)
	local spacing = 1
	local name = unitTypeToBuild:Name()
	if unitTable[name].isWeapon then spacing = 10 end
	if unitTable[name].bigExplosion then spacing = 20 end
	if unitTable[name].buildOptions then spacing = 21 end
	return spacing
end

function BuildSiteHandler:ClosestBuildSpot(builder, position, unitTypeToBuild, minimumDistance, attemptNumber, buildDistance)
	-- return self:ClosestBuildSpotInSpiral(builder, unitTypeToBuild, position)
	if attemptNumber == nil then EchoDebug("looking for build spot for " .. builder:Name() .. " to build " .. unitTypeToBuild:Name()) end
	local minDistance = minimumDistance or self:GetBuildSpacing(unitTypeToBuild)
	if buildDistance == nil then buildDistance = 100 end
	local tmpAttemptNumber = attemptNumber or 0
	local pos = nil

	if tmpAttemptNumber > 0 then
		local searchAngle = (tmpAttemptNumber - 1) / 3 * math.pi
		local searchRadius = 2 * buildDistance / 3
		local searchPos = api.Position()
		searchPos.x = position.x + searchRadius * math.sin(searchAngle)
		searchPos.z = position.z + searchRadius * math.cos(searchAngle)
		searchPos.y = position.y
		EchoDebug(math.ceil(searchPos.x) .. ", " .. math.ceil(searchPos.z))
		pos = map:FindClosestBuildSite(unitTypeToBuild, searchPos, searchRadius / 2, minDistance)
	else
		pos = map:FindClosestBuildSite(unitTypeToBuild, position, buildDistance, minDistance)
	end

	-- if pos == nil then EchoDebug("pos is nil before check") end

	-- check that we haven't got an offmap order, that it's possible to build the unit there, that it's not in front of a factory or on top of a metal spot, and that the builder can actually move there
	pos = self:CheckBuildPos(pos, unitTypeToBuild, builder, position)

	if pos == nil then
		-- EchoDebug("attempt number " .. tmpAttemptNumber .. " nil")
		-- first try increasing tmpAttemptNumber, up to 7
		if tmpAttemptNumber < 19 then
			if tmpAttemptNumber == 7 or tmpAttemptNumber == 13 then
				buildDistance = buildDistance + 100
				if minDistance < 5 then
					minDistance = minDistance + 2
				elseif minDistance < 21 then
					minDistance = minDistance - 4
				end
			end
			pos = self:ClosestBuildSpot(builder, position, unitTypeToBuild, minDistance, tmpAttemptNumber + 1, buildDistance)
		else
			-- check manually check in a spiral
			EchoDebug("trying spiral check")
			pos = self:ClosestBuildSpotInSpiral(builder, unitTypeToBuild, position, minDistance * 16)
		end
	end

	return pos
end

function BuildSiteHandler:ClosestBuildSpotInSpiral(builder, unitTypeToBuild, position, dist, segmentSize, direction, i)
	local pos = nil
	if dist == nil then dist = 64 end
	if segmentSize == nil then segmentSize = 1 end
	if direction == nil then direction = 1 end
	if i == nil then i = 0 end
	-- have to set it this way, otherwise both just point to the same set of data, and originalPosition doesn't stay the same
	local originalPosition = api.Position()
	originalPosition.x = position.x
	originalPosition.y = position.y
	originalPosition.z = position.z

	EchoDebug("new spiral search")
	while segmentSize < 8 do
		EchoDebug(i .. " " .. direction .. " " .. segmentSize .. " : " .. math.ceil(position.x) .. " " .. math.ceil(position.z))
		if direction == 1 then
			position.x = position.x + dist
		elseif direction == 2 then
			position.z = position.z + dist
		elseif direction == 3 then
			position.x = position.x - dist
		elseif direction == 4 then
			position.z = position.z - dist
		end
		pos = self:CheckBuildPos(position, unitTypeToBuild, builder, originalPosition)
		if pos ~= nil then break end
		i = i + 1
		if i == segmentSize then
			i = 0
			direction = direction + 1
			if direction == 3 then
				segmentSize = segmentSize + 1
			elseif direction == 5 then
				segmentSize = segmentSize + 1
				direction = 1
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
	for i, factory in pairs(ai.factoriesAtLevel[maxLevel]) do
		if not ai.outmodedFactoryID[factory.id] then
			local dist = distance(bpos, factory.position)
			if dist < minDist then
				minDist = dist
				factoryPos = factory.position
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

function BuildSiteHandler:DontBuildHere(position, size, uid)
	EchoDebug("new no build zone: " .. position.x .. ", " .. position.z .. "  " .. size)
	size = size * 1.33
	table.insert(self.seriouslyDont, {position = position, size = size, uid = uid})
	self:PlotAllDebug()
end

-- to handle factory deaths
function BuildSiteHandler:DoBuildHereNow(uid)
	for i, square in pairs(self.seriouslyDont) do
		if square.uid == uid then
			table.remove(self.seriouslyDont, i)
		end
	end
	self:PlotAllDebug()
end

function BuildSiteHandler:DontBuildOnMetalOrGeoSpots()
	local spots = ai.scoutSpots["air"][1]
	for i, p in pairs(spots) do
		self:DontBuildHere(p, 60)
	end
end

function BuildSiteHandler:PlotAllDebug()
	if not DebugEnabled then return end
	debugPlotBuildFile = assert(io.open("debugbuildplot",'w'), "Unable to write debugbuildplot")
	for i, square in pairs(self.seriouslyDont) do
		PlotSquareDebug(square.position.x, square.position.z, square.size*2/1.33, "NOBUILD")
	end
	debugPlotBuildFile:close()
end
