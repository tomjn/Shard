require "unittable"
require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TurtleHandler: " .. inStr)
	end
end

local antinukeMod = 2000
local shieldMod = 1000
local jamMod = 500

local factoryPriority = 3 -- multiplied by tech level

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
		if ut.isWeapon and not antinukeList[un] then
			self:AddDefense(upos, uid, un)
		elseif antinukeList[un] then
			self:AddShell(upos, uid, 1, "antinuke", 72000)
		elseif shieldList[un] then
			self:AddShell(upos, uid, 1, "shield", 450)
		elseif ut.jammerRadius ~= 0 then
			self:AddShell(upos, uid, 1, "jam", ut.jammerRadius)
		elseif defendList[un] then
			self:AddTurtle(upos, uid, defendList[un])
		elseif ut.buildOptions then
			self:AddTurtle(upos, uid, factoryPriority * ut.techLevel)
		end
	end
end

function TurtleHandler:UnitDead(unit)
	local un = unit:Name()
	local ut = unitTable[un]
	if ut.isBuilding then
		if ut.isWeapon or shieldList[un] then
			self:RemoveShell(unit:ID())
		elseif defendList[un] or ut.buildOptions then
			self:RemoveTurtle(unit:ID())
		end
	end
end


function TurtleHandler:AddTurtle(position, uid, priority)
	local turtle = {position = position, uid = uid, priority = priority, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 0}
	for i, shell in pairs(self.shells) do
		local dist = distance(position, shell.position)
		if dist < shell.radius then
			turtle[shell.layer] = turtle[shell.layer] + shell.value
			table.insert(shell.attachments, turtle)
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
		self:AddShell(position, uid, defense, "ground", ut.groundRange * 0.5)
	end
	if ut.airRange ~= 0 then
		self:AddShell(position, uid, defense, "air", ut.airRange * 0.5)
	end
	if ut.submergedRange ~= 0 then
		self:AddShell(position, uid, defense, "submerged", ut.submergedRange * 0.5)
	end
end

function TurtleHandler:AddShell(position, uid, value, layer, radius)
	local attachments = {}
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		if dist < radius then
			turtle[layer] = turtle[layer] + value
			table.insert(attachments, turtle)
		end
	end
	table.insert(self.shells, {position = position, uid = uid, value = value, layer = layer, radius = radius, attachments = attachments})
end

function TurtleHandler:RemoveShell(uid)
	for si, shell in pairs(self.shells) do
		if shell.uid == uid then
			for ti, turtle in pairs(shell.attachments) do
				turtle[shell.layer] = turtle[shell.layer] - shell.value
			end
			table.remove(self.shells, si)
		end
	end
end

function TurtleHandler:BestTurtle(position, unitName, most)
	if position == nil then return end
	if unitName == nil then return end
	local ut = unitTable[unitName]
	local ground, air, submerged, antinuke, shield, jam
	if most then
		-- if we're looking for the most turtled position, count everything
		ground = true
		air = true
		submerged = true
		antinuke = true
		shield = true
		jam = true
	else
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
		end
	end
	local bestDist = 10000
	local best
	for i, turtle in pairs(self.turtles) do
		local mod = 0
		if ground then
			mod = mod + turtle.ground
		end
		if air then
			mod = mod + turtle.air
		end
		if submerged then
			mod = mod + turtle.submerged
		end
		if antinuke then
			mod = mod + turtle.antinuke * antinukeMod
		end
		if shield then
			mod = mod + turtle.shield * shieldMod
		end
		if jam then
			mod = mod + turtle.jam * jamMod
		end
		local dist = distance(position, turtle.position)
		if most then
			-- if we're finding the most turtled position
			dist = dist - mod
		else
			-- if we're looking for a vulnerable spot to build up
			dist = dist + (mod / turtle.priority)
		end
		if dist < bestDist then
			bestDist = dist
			best = turtle.position
		end
	end
	return best
end