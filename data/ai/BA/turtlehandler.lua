require "unittable"
require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TurtleHandler: " .. inStr)
	end
end

local antinukeMod = 1000
local shieldMod = 1000
local jamMod = 1000
local radarMod = 1000
local sonarMod = 1000
local distanceMod = 20

local factoryPriority = 4 -- added to tech level. above this priority allows two of the same type of defense tower.

-- this is added to the turtle's priority if a shell of this layer is added to it
local layerPriority = {}
layerPriority["radar"] = 1
layerPriority["sonar"] = 1
layerPriority["jam"] = 1
layerPriority["antinuke"] = 2
layerPriority["shield"] = 2

TurtleHandler = class(Module)

function TurtleHandler:Name()
	return "TurtleHandler"
end

function TurtleHandler:internalName()
	return "turtlehandler"
end

function TurtleHandler:Init()
	self.turtles = {} -- things to protect
	self.shells = {} -- defense buildings, shields, and jamming
	self.totalPriority = 0
end

function TurtleHandler:UnitBuilt(unit)
	local un = unit:Name()
	local ut = unitTable[un]
	if ut.isBuilding then
		local upos = unit:GetPosition()
		local uid = unit:ID()
		if turtleList[un] then
			self:AddTurtle(upos, uid, turtleList[un])
		elseif ut.buildOptions then
			self:AddTurtle(upos, uid, factoryPriority + ut.techLevel)
		elseif ut.isWeapon and not antinukeList[un] and not nukeList[un] and not bigPlasmaList[un] then
			self:AddDefense(upos, uid, un)
		elseif antinukeList[un] then
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
	end
end

function TurtleHandler:UnitDead(unit)
	local un = unit:Name()
	local ut = unitTable[un]
	if ut.isBuilding then
		if ut.isWeapon or shieldList[un] then
			self:RemoveShell(unit:ID())
		elseif turtleList[un] or ut.buildOptions then
			self:RemoveTurtle(unit:ID())
		end
	end
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
	self.totalPriority = self.totalPriority + priorityAddition
	table.insert(shell.attachments, turtle)
end

function TurtleHandler:Detach(turtle, shell)
	turtle[shell.layer] = turtle[shell.layer] - shell.value
	turtle.nameCounts[shell.uname] = turtle.nameCounts[shell.uname] - 1
	local priorityAddition = layerPriority[shell.layer] or 0
	turtle.priority = turtle.priority - priorityAddition
	self.totalPriority = self.totalPriority - priorityAddition
end

function TurtleHandler:AddTurtle(position, uid, priority)
	local nameLimit = 1
	if priority > factoryPriority then nameLimit = 2 end
	local turtle = {position = position, uid = uid, nameCounts = {}, nameLimit = nameLimit, priority = priority, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 0, radar = 0, sonar = 0}
	for i, shell in pairs(self.shells) do
		local dist = distance(position, shell.position)
		if dist < shell.radius then
			self:Attach(turtle, shell)
		end
	end
	table.insert(self.turtles, turtle)
	self.totalPriority = self.totalPriority + priority
end

function TurtleHandler:RemoveTurtle(uid)
	for i, turtle in pairs(self.turtles) do
		if turtle.uid == uid then
			table.remove(self.turtles, i)
			self.totalPriority = self.totalPriority - turtle.priority
		end
	end
	for si, shell in pairs(self.shells) do
		for ti, turtle in pairs(shell.attachments) do
			if turtle.uid == uid then
				table.remove(shell.attachments, ti)
			end
		end
	end
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
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		if dist < radius then
			self:Attach(turtle, shell)
		end
	end
	table.insert(self.shells, shell)
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
end

function TurtleHandler:LeastTurtled(builder, unitName, bombard)
	if builder == nil then return end
	EchoDebug("checking for least turtled from " .. builder:Name() .. " for " .. tostring(unitName) .. " bombard: " .. tostring(bombard))
	if unitName == nil then return end
	local position = builder:GetPosition()
	local ut = unitTable[unitName]
	local Metal = game:GetResourceByName("Metal")
	local ground, air, submerged, antinuke, shield, jam, radar, sonar
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
	elseif shieldList[unitName] then
		shield = true
	elseif ut.jammerRadius ~= 0 then
		jam = true
	elseif ut.radarRadius ~= 0 then
		radar = true
	elseif ut.sonarRadius ~= 0 then
		sonar = true
	end
	local bestDist = 100000
	local best
	for i, turtle in pairs(self.turtles) do
		local enough = false
		local isLocal = true
		if unitName ~= nil then
			if turtle.nameCounts[unitName] == nil or turtle.nameCounts[unitName] == 0 then
				-- not enough
			elseif turtle.nameCounts[unitName] >= turtle.nameLimit then
				EchoDebug("too many " .. unitName .. " at turtle")
				enough = true
			end
		end
		if not enough and (ground or air or submerged) then
			isLocal = ai.maphandler:CheckDefenseLocalization(unitName, turtle.position)
		end
		if not enough and isLocal then
			local okay = ai.maphandler:UnitCanGoHere(builder, turtle.position) 
			if okay and bombard and unitName ~= nil then 
				okay = ai.targethandler:IsBombardPosition(turtle.position, unitName)
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
					local dist = distance(position, turtle.position)
					dist = dist - (modLimit * distanceMod)
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
	return best
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
				local mod = turtle.ground + turtle.air + turtle.submerged
				EchoDebug("turtled: " .. mod .. ", priority: " .. turtle.priority .. ", total priority: " .. self.totalPriority)
				if mod ~= 0 then
					local dist = distance(position, turtle.position)
					dist = dist - (mod * distanceMod)
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
	return best
end