require "common"

local DebugEnabled = false
local DebugPlotEnabled = false
local debugPlotTurtleFile

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TurtleHandler: " .. inStr)
	end
end

local function PlotPointDebug(x, z, label)
	label = string.format("%.1f", label)
	debugPlotTurtleFile:write(math.ceil(x) .. " " .. math.ceil(z) .. " " .. label .. "\n")
end

local maxOrganDistance = 200

local antinukeMod = 1000
local shieldMod = 1000
local jamMod = 1000
local radarMod = 1000
local sonarMod = 1000
local distanceMod = 1.5

local factoryPriority = 4 -- added to tech level. above this priority allows two of the same type of defense tower.

-- this is added to the turtle's priority if a shell of this layer is added to it
local layerPriority = {}
layerPriority["jam"] = 1
layerPriority["shield"] = 2

TurtleHandler = class(Module)

function TurtleHandler:Name()
	return "TurtleHandler"
end

function TurtleHandler:internalName()
	return "turtlehandler"
end

function TurtleHandler:Init()
	self.turtles = {} -- zones to protect
	self.looseOrgans = {} -- things to protect not yet in a protected zone
	self.shells = {} -- defense buildings, shields, and jamming
	self.totalPriority = 0
end

function TurtleHandler:UnitCreated(unit)
	local un = unit:Name()
	local ut = unitTable[un]
	if ut.isBuilding then
		local upos = unit:GetPosition()
		local uid = unit:ID()
		if ut.isWeapon and not ut.buildOptions and not antinukeList[un] and not nukeList[un] and not bigPlasmaList[un] then
			self:AddDefense(upos, uid, un)
		else
			if antinukeList[un] then
				self:AddShell(upos, uid, un, 1, "antinuke", 72000)
			elseif shieldList[un] then
				self:AddShell(upos, uid, un, 1, "shield", 450)
			elseif ut.jammerRadius ~= 0 then
				self:AddShell(upos, uid, un, 1, "jam", ut.jammerRadius)
			elseif ut.radarRadius ~= 0 then
				self:AddShell(upos, uid, un, 1, "radar", ut.radarRadius * 0.67)
			elseif ut.sonarRadius ~= 0 then
				self:AddShell(upos, uid, un, 1, "sonar", ut.sonarRadius * 0.67)
			end
			self:AddOrgan(upos, uid, un)
		end
	end
end

function TurtleHandler:UnitDead(unit)
	local un = unit:Name()
	local ut = unitTable[un]
	local uid = unit:ID()
	if ut.isBuilding then
		if ut.isWeapon or shieldList[un] then
			self:RemoveShell(uid)
		else
			self:RemoveOrgan(uid)
		end
	end
end

function TurtleHandler:AddOrgan(position, unitID, unitName)
	-- calculate priority
	local priority = 0
	local ut = unitTable[unitName]
	if turtleList[unitName] then
		priority = turtleList[unitName]
	elseif antinukeList[unitName] then
		priority = 2
	elseif shieldList[unitName] then
		priority = 2
	else
		if ut.buildOptions then
			priority = priority + factoryPriority + ut.techLevel
		end
		if ut.extractsMetal > 0 then
			priority = priority + (ut.extractsMetal * 1000)
		end
		if ut.totalEnergyOut > 0 then
			priority = priority + (ut.totalEnergyOut / 200)
		end
		if ut.jammerRadius > 0 then
			priority = priority + (ut.jammerRadius / 700)
		end
		if ut.radarRadius > 0 then
			priority = priority + (ut.radarRadius / 3500)
		end
		if ut.sonarRadius > 0 then
			priority = priority + (ut.sonarRadius / 2400)
		end
		priority = priority + (ut.metalCost / 1000)
	end
	-- create the organ
	local organ = { priority = priority, position = position, uid = unitID }
	-- find a turtle to attach to
	local nearestDist = maxOrganDistance
	local nearestTurtle
	for i, turtle in pairs(self.turtles) do
		if turtle.water == ut.needsWater then
			local dist = Distance(position, turtle.position)
			if dist < nearestDist then
				nearestDist = dist
				nearestTurtle = turtle
			end
		end
	end
	if nearestTurtle == nil then
		nearestTurtle = self:AddTurtle(position, ut.needsWater)
	end
	self:Transplant(nearestTurtle, organ)
	self:PlotAllDebug()
end

function TurtleHandler:RemoveOrgan(uid)
	local foundOrgan = false
	local emptyTurtle = false
	for ti, turtle in pairs(self.turtles) do
		for oi, organ in pairs(turtle.organs) do
			if organ.uid == uid then
				turtle.priority = turtle.priority - organ.priority
				self.totalPriority = self.totalPriority - organ.priority
				table.remove(turtle.organs, oi)
				if #turtle.organs == 0 then
					emptyTurtle = turtle
					table.remove(self.turtles, ti)
				end
				foundOrgan = true
				break
			end
		end
		if foundOrgan then break end
	end
	if emptyTurtle then
		for si, shell in pairs(self.shells) do
			for ti, turtle in pairs(shell.attachments) do
				if turtle == emptyTurtle then
					table.remove(shell.attachments, ti)
				end
			end
		end
	end
	self:PlotAllDebug()
end

function TurtleHandler:Transplant(turtle, organ)
	table.insert(turtle.organs, organ)
	turtle.priority = turtle.priority + organ.priority
	if turtle.priority > factoryPriority then turtle.nameLimit = 2 end
	self.totalPriority = self.totalPriority + organ.priority
end

function TurtleHandler:Attach(turtle, shell)
	turtle[shell.layer] = turtle[shell.layer] + shell.value
	if turtle.nameCounts[shell.uname] == nil then
		turtle.nameCounts[shell.uname] = 1
	else
		turtle.nameCounts[shell.uname] = turtle.nameCounts[shell.uname] + 1
	end
	local priorityAddition = layerPriority[shell.layer] or 0
	turtle.priority = turtle.priority + priorityAddition
	if turtle.priority > factoryPriority then turtle.nameLimit = 2 end
	self.totalPriority = self.totalPriority + priorityAddition
	table.insert(shell.attachments, turtle)
end

function TurtleHandler:Detach(turtle, shell)
	turtle[shell.layer] = turtle[shell.layer] - shell.value
	turtle.nameCounts[shell.uname] = turtle.nameCounts[shell.uname] - 1
	local priorityAddition = layerPriority[shell.layer] or 0
	turtle.priority = turtle.priority - priorityAddition
	if turtle.priority <= factoryPriority then turtle.nameLimit = 1 end
	self.totalPriority = self.totalPriority - priorityAddition
end

function TurtleHandler:AddTurtle(position, water, priority)
	if priority == nil then priority = 0 end
	local nameLimit = 1
	if priority > factoryPriority then nameLimit = 2 end
	local turtle = {position = position, organs = {}, water = water, nameCounts = {}, nameLimit = nameLimit, priority = priority, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 0, radar = 0, sonar = 0}
	for i, shell in pairs(self.shells) do
		local dist = Distance(position, shell.position)
		if dist < shell.radius then
			self:Attach(turtle, shell)
		end
	end
	table.insert(self.turtles, turtle)
	self.totalPriority = self.totalPriority + priority
	return turtle
end

function TurtleHandler:AddDefense(position, uid, unitName)
	local ut = unitTable[unitName]
	-- effective defense ranges are less than actual ranges, because if a building is just inside a weapon range, it's not defended
	local defense = ut.metalCost
	if ut.groundRange ~= 0 then
		self:AddShell(position, uid, unitName, defense, "ground", ut.groundRange * 0.5)
	end
	if ut.airRange ~= 0 then
		self:AddShell(position, uid, unitName, defense, "air", ut.airRange * 0.5)
	end
	if ut.submergedRange ~= 0 then
		self:AddShell(position, uid, unitName, defense, "submerged", ut.submergedRange * 0.5)
	end
end

function TurtleHandler:AddShell(position, uid, uname, value, layer, radius)
	local shell = {position = position, uid = uid, uname = uname, value = value, layer = layer, radius = radius, attachments = {}}
	local nearestDist = radius * 3
	local nearestTurtle
	local attached = false
	for i, turtle in pairs(self.turtles) do
		local dist = Distance(position, turtle.position)
		if dist < radius then
			self:Attach(turtle, shell)
			attached = true
		end
		if not attached and dist < nearestDist then
			nearestDist = dist
			nearestTurtle = turtle
		end
	end
	-- if nothing is close enough, attach to the nearest turtle, so that we don't end up building infinite laser towers at the same turtle
	if not attached and nearestTurtle then
		self:Attach(nearestTurtle, shell)
	end
	table.insert(self.shells, shell)
	self:PlotAllDebug()
end

function TurtleHandler:RemoveShell(uid)
	for si, shell in pairs(self.shells) do
		if shell.uid == uid then
			for ti, turtle in pairs(shell.attachments) do
				self:Detach(turtle, shell)
			end
			table.remove(self.shells, si)
		end
	end
	self:PlotAllDebug()
end

function TurtleHandler:LeastTurtled(builder, unitName, bombard)
	if builder == nil then return end
	EchoDebug("checking for least turtled from " .. builder:Name() .. " for " .. tostring(unitName) .. " bombard: " .. tostring(bombard))
	if unitName == nil then return end
	local position = builder:GetPosition()
	local ut = unitTable[unitName]
	local Metal = game:GetResourceByName("Metal")
	local ground, air, submerged, antinuke, shield, jam, radar, sonar
	local priorityFloor = 1
	if ut.isWeapon and not antinukeList[unitName] then
		if ut.groundRange ~= 0 then
			ground = true
		end
		if ut.airRange ~= 0 then
			air = true
		end
		if ut.submergedRange ~= 0 then
			submerged = true
		end
	elseif antinukeList[unitName] then
		antinuke = true
		priorityFloor = 5
	elseif shieldList[unitName] then
		shield = true
		priorityFloor = 5
	elseif ut.jammerRadius ~= 0 then
		jam = true
		priorityFloor = 5
	elseif ut.radarRadius ~= 0 then
		radar = true
	elseif ut.sonarRadius ~= 0 then
		sonar = true
	end
	local bestDist = 100000
	local best
	for i, turtle in pairs(self.turtles) do
		local important = turtle.priority >= priorityFloor -- so that for example we don't build shields where there's just a mex
		local enough = false
		local isLocal = true
		if unitName ~= nil and important then
			if turtle.nameCounts[unitName] == nil or turtle.nameCounts[unitName] == 0 then
				-- not enough
			elseif turtle.nameCounts[unitName] >= turtle.nameLimit then
				EchoDebug("too many " .. unitName .. " at turtle")
				enough = true
			end
		end
		if not enough and (ground or air or submerged) and important then
			-- don't build land shells on water turtles or water shells on land turtles
			isLocal = unitTable[unitName].needsWater == turtle.water
		end
		if not enough and isLocal and important then
			local okay = ai.maphandler:UnitCanGoHere(builder, turtle.position) 
			if okay and bombard and unitName ~= nil then 
				okay = ai.targethandler:IsBombardPosition(turtle.position, unitName)
			end
			if okay and (radar or sonar or shield or antinuke or jammer) then
				-- only build these things at already defended spots
				okay = turtle.ground + turtle.air + turtle.submerged > 0
			end
			if okay then
				local mod = 0
				if ground then mod = mod + turtle.ground end
				if air then mod = mod + turtle.air end
				if submerged then mod = mod + turtle.submerged end
				if antinuke then mod = mod + turtle.antinuke * antinukeMod end
				if shield then mod = mod + turtle.shield * shieldMod end
				if jam then mod = mod + turtle.jam * jamMod end
				if radar then mod = mod + turtle.radar * radarMod end
				if sonar then mod = mod + turtle.sonar * sonarMod end
				local modLimit = 10000
				if ground or air or submerged then
					modLimit = (turtle.priority / self.totalPriority) * Metal.income * 65
					modLimit = math.floor(modLimit)
				end
				local modDefecit = modLimit - mod
				EchoDebug("turtled: " .. mod .. ", limit: " .. tostring(modLimit) .. ", priority: " .. turtle.priority .. ", total priority: " .. self.totalPriority)
				if mod == 0 or mod < ut.metalCost or (mod < modLimit and modDefecit < ut.metalCost * 3) then
					local dist = Distance(position, turtle.position)
					dist = dist - (modDefecit * distanceMod)
					EchoDebug("distance: " .. dist)
					if dist < bestDist then
						EchoDebug("best distance")
						bestDist = dist
						best = turtle.position
					end
				end
			end
		end
	end
	if best then
		local newpos = api.Position()
		newpos.x = best.x
		newpos.z = best.z
		newpos.y = best.y
		return newpos
	else
		return nil
	end
end

function TurtleHandler:MostTurtled(builder, bombard)
	if builder == nil then return end
	EchoDebug("checking for most turtled from " .. builder:Name() .. ", bombard: " .. tostring(bombard))
	local position = builder:GetPosition()
	local bestDist = 100000
	local best
	for i, turtle in pairs(self.turtles) do
		if ai.maphandler:UnitCanGoHere(builder, turtle.position) then
			local okay = true
			if bombard then 
				okay = ai.targethandler:IsBombardPosition(turtle.position, bombard)
			end
			if okay then
				local mod = turtle.ground + turtle.air + turtle.submerged + (turtle.shield * shieldMod) + (turtle.jam * jamMod)
				EchoDebug("turtled: " .. mod .. ", priority: " .. turtle.priority .. ", total priority: " .. self.totalPriority)
				if mod ~= 0 then
					local dist = Distance(position, turtle.position)
					dist = dist - (mod * distanceMod * 2)
					EchoDebug("distance: " .. dist)
					if dist < bestDist then
						EchoDebug("best distance")
						bestDist = dist
						best = turtle.position
					end
				end
			end
		end
	end
	if best then
		local newpos = api.Position()
		newpos.x = best.x
		newpos.z = best.z
		newpos.y = best.y
		return newpos
	else
		return nil
	end
end

function TurtleHandler:GetTotalPriority()
	return self.totalPriority
end

function TurtleHandler:PlotAllDebug()
	if DebugPlotEnabled then
		debugPlotTurtleFile= assert(io.open("debugturtleplot",'w'), "Unable to write debugturtleplot")
		for i, turtle in pairs(self.turtles) do
			PlotPointDebug(turtle.position.x, turtle.position.z, turtle.priority)
		end
		debugPlotTurtleFile:close()
	end
end