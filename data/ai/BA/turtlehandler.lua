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
	if label ~= "LIMB" then label = string.format("%.1f", label) end
	debugPlotTurtleFile:write(math.ceil(x) .. " " .. math.ceil(z) .. " " .. label .. "\n")
end

local maxOrganDistance = 400

local babySize = 200
local outpostSize = 250
local baseSize = 300

local baseOrgans = 4
local outpostOrgans = 2

local outpostLimbs = 2
local baseLimbs = 3

local layerMod = {
	ground = 1,
	air = 1,
	submerged = 1,
	antinuke = 1000,
	shield = 1000,
	jam = 1000,
	radar = 1000,
	sonar = 1000,
}

local missingFactoryDefenseDistance = 1500 -- if a turtle with a factory has no defense, subtract this much from distance
local modDistance = 1.25

local factoryPriority = 4 -- added to tech level. above this priority allows two of the same type of defense tower.

local basePriority = factoryPriority + 1
local outpostPriority = 2

local exteriorLayer = { ground = 1, submerged = 1 }
local interiorLayer = { air = 1, antinuke = 1, shield = 1, jam = 1, radar = 1, sonar = 1 }
local hurtyLayer = { ground = 1, submerged = 1, air = 1 }

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
			if dist < turtle.size then
				if dist < nearestDist then
					nearestDist = dist
					nearestTurtle = turtle
				end
			end
		end
	end
	-- make a new turtle if necessary
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
	if #turtle.limbs < baseLimbs and turtle.priority >= basePriority and #turtle.organs >= baseOrgans then
		self:Base(turtle, baseSize, baseLimbs)
	elseif #turtle.limbs < outpostLimbs and turtle.priority >= outpostPriority and #turtle.organs >= outpostOrgans then
		self:Base(turtle, outpostSize, outpostLimbs)
	end
	self.totalPriority = self.totalPriority + organ.priority
end

function TurtleHandler:Attach(limb, shell)
	local turtle = limb.turtle
	turtle[shell.layer] = turtle[shell.layer] + shell.value
	if turtle.nameCounts[shell.uname] == nil then
		turtle.nameCounts[shell.uname] = 1
	else
		turtle.nameCounts[shell.uname] = turtle.nameCounts[shell.uname] + 1
	end
	limb[shell.layer] = limb[shell.layer] + shell.value
	if limb.nameCounts[shell.uname] == nil then
		limb.nameCounts[shell.uname] = 1
	else
		limb.nameCounts[shell.uname] = limb.nameCounts[shell.uname] + 1
	end
	table.insert(shell.attachments, limb)
end

function TurtleHandler:Detach(limb, shell)
	local turtle = limb.turtle
	turtle[shell.layer] = turtle[shell.layer] - shell.value
	turtle.nameCounts[shell.uname] = turtle.nameCounts[shell.uname] - 1
	limb[shell.layer] = limb[shell.layer] - shell.value
	limb.nameCounts[shell.uname] = limb.nameCounts[shell.uname] - 1
end

function TurtleHandler:InitializeInteriorLayers(limb)
	for layer, nothing in pairs(interiorLayer) do
		limb[layer] = 0
	end
end

function TurtleHandler:Base(turtle, size, limbs)
	turtle.size = size
	for li, limb in pairs(turtle.limbs) do
		if limb ~= turtle.firstLimb then
			self:InitializeInteriorLayers(limb)
			table.insert(turtle.interiorLimbs, limb)
		end
	end
	turtle.limbs = {}
	local angleAdd = twicePi / limbs
	local angle = math.random() * twicePi
	for l = 1, limbs do
		local limb = { turtle = turtle, nameCounts = {}, ground = 0, submerged = 0 }
		limb.position = RandomAway(turtle.position, size, false, angle)
		for i, shell in pairs(self.shells) do
			if exteriorLayer[shell.layer] then
				local dist = Distance(limb.position, shell.position)
				if dist < shell.radius then
					self:Attach(limb, shell)
				end
			end
		end
		table.insert(turtle.limbs, limb)
		angle = angle + angleAdd
		if angle > twicePi then angle = angle - twicePi end
	end
end

function TurtleHandler:AddTurtle(position, water, priority)
	if priority == nil then priority = 0 end
	local firstLimb = { position = position, nameCounts = {}, ground = 0, submerged = 0 }
	self:InitializeInteriorLayers(firstLimb)
	local turtle = {position = position, size = babySize, organs = {}, limbs = { firstLimb }, interiorLimbs = { firstLimb }, firstLimb = firstLimb, water = water, nameCounts = {}, priority = priority, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 0, radar = 0, sonar = 0}
	firstLimb.turtle = turtle
	for i, shell in pairs(self.shells) do
		local dist = Distance(position, shell.position)
		if dist < shell.radius then
			self:Attach(turtle.firstLimb, shell)
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
	local nearestLimb
	local attached = false
	for i, turtle in pairs(self.turtles) do
		local checkThese
		if exteriorLayer[layer] then
			checkThese = turtle.limbs
		else
			checkThese = turtle.interiorLimbs
		end
		for li, limb in pairs(checkThese) do
			local dist = Distance(position, limb.position)
			if dist < radius then
				self:Attach(limb, shell)
				attached = true
			end
			if not attached and dist < nearestDist then
				nearestDist = dist
				nearestLimb = limb
			end
		end
	end
	-- if nothing is close enough, attach to the nearest turtle, so that we don't end up building infinite laser towers at the same turtle
	if not attached and nearestTurtle then
		self:Attach(nearestLimb, shell)
	end
	table.insert(self.shells, shell)
	self:PlotAllDebug()
end

function TurtleHandler:RemoveShell(uid)
	for si, shell in pairs(self.shells) do
		if shell.uid == uid then
			for li, limb in pairs(shell.attachments) do
				self:Detach(limb, shell)
			end
			table.remove(self.shells, si)
		end
	end
	self:PlotAllDebug()
end

function TurtleHandler:LeastTurtled(builder, unitName, bombard, oneOnly)
	if builder == nil then return end
	EchoDebug("checking for least turtled from " .. builder:Name() .. " for " .. tostring(unitName) .. " bombard: " .. tostring(bombard))
	if unitName == nil then return end
	local position = builder:GetPosition()
	local ut = unitTable[unitName]
	local Metal = game:GetResourceByName("Metal")
	local priorityFloor = 1
	local layer
	if ut.isWeapon and not antinukeList[unitName] then
		if ut.groundRange ~= 0 then
			layer = "ground"
		elseif ut.airRange ~= 0 then
			layer = "air"
		elseif ut.submergedRange ~= 0 then
			layer = "submerged"
		end
	elseif antinukeList[unitName] then
		layer = "antinuke"
		priorityFloor = 5
	elseif shieldList[unitName] then
		layer = "shield"
		priorityFloor = 5
	elseif ut.jammerRadius ~= 0 then
		layer = "jam"
		priorityFloor = 5
	elseif ut.radarRadius ~= 0 then
		layer = "radar"
	elseif ut.sonarRadius ~= 0 then
		layer = "sonar"
	end
	local bestDist = 100000
	local best
	local bydistance = {}
	for i, turtle in pairs(self.turtles) do
		local important = turtle.priority >= priorityFloor -- so that for example we don't build shields where there's just a mex
		local isLocal = true
		if important then
			-- don't build land shells on water turtles or water shells on land turtles
			isLocal = unitTable[unitName].needsWater == turtle.water
		end
		if isLocal and important then
			local modLimit = 10000
			if hurtyLayer[layer] then
				modLimit = (turtle.priority / self.totalPriority) * Metal.income * 65
				modLimit = math.floor(modLimit)
			end
			local missingFactoryDefense = hurtyLayer[layer] and turtle[layer] == 0 and turtle.priority > factoryPriority
			local checkThese
			if interiorLayer[layer] then
				if layer == "air" or turtle.ground + turtle.air + turtle.submerged > 0 then
					checkThese = turtle.interiorLimbs
				else
					checkThese = {}
				end
			else
				checkThese = turtle.limbs
			end
			for li, limb in pairs(checkThese) do
				local enough
				if interiorLayer[layer] then
					enough = turtle.nameCounts[unitName] ~= nil and turtle.nameCounts[unitName] ~= 0
				else
					local turtleEnough = false
					if turtle.nameCounts[unitName] ~= nil then
						turtleEnough = turtle.nameCounts[unitName] >= #turtle.limbs
					end
					enough = (limb.nameCounts[unitName] ~= nil and limb.nameCounts[unitName] ~= 0) or turtleEnough
				end
				local okay = false
				if not enough then
					okay = ai.maphandler:UnitCanGoHere(builder, limb.position) 
				end
				if okay and bombard and unitName ~= nil then 
					okay = ai.targethandler:IsBombardPosition(limb.position, unitName)
				end
				if okay then
					local mod
					if interiorLayer[layer] then
						mod = turtle[layer]
					else
						mod = limb[layer]
					end
					mod = mod * layerMod[layer]
					local modDefecit = modLimit - mod
					EchoDebug("turtled: " .. mod .. ", limit: " .. tostring(modLimit) .. ", priority: " .. turtle.priority .. ", total priority: " .. self.totalPriority)
					if mod == 0 or mod < ut.metalCost or mod < modLimit then
						local dist = Distance(position, limb.position)
						dist = dist - (modDefecit * modDistance)
						if missingFactoryDefense then dist = dist - missingFactoryDefenseDistance end
						EchoDebug("distance: " .. dist)
						if oneOnly then
							if dist < bestDist then
								EchoDebug("best distance")
								bestDist = dist
								best = limb.position
							end
						else
							bydistance[dist] = limb.position
						end
					end
				end
			end
		end
	end
	if oneOnly then
		if best then
			local newpos = api.Position()
			newpos.x = best.x
			newpos.z = best.z
			newpos.y = best.y
			return newpos
		else
			return nil
		end
	else
		local sorted = {}
		for dist, pos in pairsByKeys(bydistance) do
			local newpos = api.Position()
			newpos.x = pos.x
			newpos.z = pos.z
			newpos.y = pos.y
			table.insert(sorted, newpos)
		end
		EchoDebug("outputting " .. #sorted .. " least turtles")
		return sorted
	end
end

function TurtleHandler:MostTurtled(builder, bombard, oneOnly)
	if builder == nil then return end
	EchoDebug("checking for most turtled from " .. builder:Name() .. ", bombard: " .. tostring(bombard))
	local position = builder:GetPosition()
	local bestDist = 100000
	local best
	local bydistance = {}
	for i, turtle in pairs(self.turtles) do
		if ai.maphandler:UnitCanGoHere(builder, turtle.position) then
			local okay = true
			if bombard then 
				okay = ai.targethandler:IsBombardPosition(turtle.position, bombard)
			end
			if okay then
				local mod = turtle.ground + turtle.air + turtle.submerged + (turtle.shield * layerMod["shield"]) + (turtle.jam * layerMod["jam"])
				EchoDebug("turtled: " .. mod .. ", priority: " .. turtle.priority .. ", total priority: " .. self.totalPriority)
				if mod ~= 0 then
					local dist = Distance(position, turtle.position)
					dist = dist - (mod * modDistance * 2)
					EchoDebug("distance: " .. dist)
					if oneOnly then
						if dist < bestDist then
							EchoDebug("best distance")
							bestDist = dist
							best = turtle.position
						end
					else
						bydistance[dist] = turtle.position
					end
				end
			end
		end
	end
	if oneOnly then
		if best then
			local newpos = api.Position()
			newpos.x = best.x
			newpos.z = best.z
			newpos.y = best.y
			return newpos
		else
			return nil
		end
	else
		local sorted = {}
		for dist, pos in pairsByKeys(bydistance) do
			local newpos = api.Position()
			newpos.x = pos.x
			newpos.z = pos.z
			newpos.y = pos.y
			table.insert(sorted, newpos)
		end
		EchoDebug("outputting " .. #sorted .. " most turtles")
		return sorted
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
			for li, limb in pairs(turtle.limbs) do
				PlotPointDebug(limb.position.x, limb.position.z, "LIMB")
			end
		end
		debugPlotTurtleFile:close()
	end
end