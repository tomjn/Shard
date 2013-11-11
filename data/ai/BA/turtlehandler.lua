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

TurtleHandler = class(Module)

function TurtleHandler:Name()
	return "TurtleHandler"
end

function TurtleHandler:internalName()
	return "TurtleHandler"
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
			self:AddAntinuke(upos, uid, 72000)
		elseif shieldList[un] then
			self:AddShield(upos, uid, 500)
		elseif ut.jammerRadius ~= 0 then
			self:AddJammer(upos, uid, ut.jammerRadius)
		elseif defendList[un] or ut.buildOptions then
			self:AddTurtle(upos, uid, priority)
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
	table.insert(self.turtles, {position = position, uid = uid, priority = priority, groundDefended = 0, airDefended = 0, submergedDefended = 0, antinuked = 0, shielded = 0, jammed = 0})
	self.totalPriority = self.totalPriority + priority
end

function TurtleHandler:RemoveTurtle(uid)
	for i, turtle in pairs(self.turtles) do
		if turtle.uid == uid then
			table.remove(self.turtles, i)
			self.totalPriority = self.totalPriority - turtle.priority
			break
		end
	end
end

function TurtleHandler:AddShield(position, uid, radius)
	local effectiveRadius = radius * 0.9
	local attachments = {}
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		if dist < effectiveRadius then
			turtle.shielded = turtle.shielded + 1
			table.insert(attachments, turtle.uid)
		end
	end
	table.insert(self.shells, {uid = uid, attachments = attachments, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 1, jam = 0})
end

function TurtleHandler:AddAntinuke(position, uid, radius)
	local attachments = {}
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		if dist < radius then
			turtle. = turtle.antinuked + 1
			table.insert(attachments, turtle.uid)
		end
	end
	table.insert(self.shells, {uid = uid, attachments = attachments, ground = 0, air = 0, submerged = 0, antinuke = 1, shield = 0, jam = 0})
end

function TurtleHandler:AddJammer(position, uid, radius)
	local attachments = {}
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		if dist < radius then
			turtle. = turtle.jammed + 1
			table.insert(attachments, turtle.uid)
		end
	end
	table.insert(self.shells, {uid = uid, attachments = attachments, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 1})
end

function TurtleHandler:AddDefense(position, uid, unitName)
	local ut = unitTable[unitName]
	-- effective defense ranges are less than actual ranges, because if a building is just inside a weapon range, it's not defended
	local ground = 0
	local air = 0
	local submerged = 0
	if ut.groundRange ~= 0 then
		ground = ut.groundRange * 0.5
	end
	if ut.airRange ~= 0 then
		air = ut.airRange * 0.5
	end
	if ut.submergedRange ~= 0 then
		submerged = ut.submergedRange * 0.5
	end
	local defense = ut.metalCost
	local attachments = {}
	for i, turtle in pairs(self.turtles) do
		local dist = distance(position, turtle.position)
		local attached = false
		if ground ~= 0 then
			if dist < ground then
				turtle.groundDefended = turtle.groundDefended + defense
				attached = true
			end
		end
		if air ~= 0 then
			if dist < air then
				turtle.airDefended = turtle.airDefended + defense
				attached = true
			end
		end
		if submerged ~= 0 then
			if dist < submerged then
				turtle.submergedDefended = turtle.submergedDefended + defense
				attached = true
			end
		end
		if attached then
			table.insert(attachments, turtle.uid)
		end
	end
	table.insert(self.shells, {uid = uid, attachments = attachments, ground = ground, air = air, submerged = submerged, antinuke = 0, shield = 0, jam = 0})
end

function TurtleHandler:RemoveShell(uid)
	for si, shell in pairs(self.shells) do
		if shell.uid == uid then
			while #shell.attachments > 0 do
				local attachment = table.remove(shell.attachments)
				for ti, turtle in pairs(self.turtles) do
					if turtle.uid == attachment.uid then
						turtle.groundDefended = turtle.groundDefended - shell.ground
						turtle.airDefended = turtle.airDefended - shell.air
						turtle.submergedDefended = turtle.submergedDefended - shell.submerged
						turtle.antinuked = turtle.antinuked - shell.antinuke
						turtle.shielded = turtle.shielded - shell.shield
						turtle.jammed = turtle.jammed - shell.jam
					end
				end
			end
			break
		end
	end
end

function TurtleHandler:BestTurtle(builder, unitName)
	if builder == nil then return end
	if unitName == nil then return end
	local bpos = builder:GetPosition()
	local ut = unitTable[unitName]
	local ground, air. submerged, shield, jam
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
	local bestDist = 10000
	local best
	for i, turtle in pairs(self.turtles) do
		local mod = 0
		if ground then
			mod = mod + turtle.groundDefended
		end
		if air then
			mod = mod + turtle.airDefended
		end
		if submerged then
			mod = mod + turtle.submergedDefended
		end
		if antinuke then
			mod = mod + turtle.antinuked * antinukeMod
		end
		if shield then
			mod = mod + turtle.shielded * shieldMod
		end
		if jam then
			mod = mod + turtle.jammed * jamMod
		end
		local dist = distance(bpos, turtle.position)
		dist = dist + (mod / turtle.priority)
		if dist < bestDist then
			bestDist = dist
			best = turtle.position
		end
	end
	return best
end