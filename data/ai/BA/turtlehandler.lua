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
local distanceMod = 100

local factoryPriority = 4 -- added to tech level

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
		if defendList[un] then
			self:AddTurtle(upos, uid, defendList[un])
		elseif ut.buildOptions then
			self:AddTurtle(upos, uid, factoryPriority + ut.techLevel)
		elseif ut.isWeapon and not antinukeList[un] and not nukeList[un] and not bigPlasmaList[un] then
			self:AddDefense(upos, uid, un)
		elseif antinukeList[un] then
			self:AddShell(upos, uid, 1, "antinuke", 72000)
		elseif shieldList[un] then
			self:AddShell(upos, uid, 1, "shield", 450)
		elseif ut.jammerRadius ~= 0 then
			self:AddShell(upos, uid, 1, "jam", ut.jammerRadius)
		elseif ut.radarRadius ~= 0 then
			self:AddShell(upos, uid, 1, "radar", ut.radarRadius * 0.5)
		elseif ut.sonarRadius ~= 0 then
			self:AddShell(upos, uid, 1, "sonar", ut.sonarRadius * 0.5)
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
	local turtle = {position = position, uid = uid, priority = priority, ground = 0, air = 0, submerged = 0, antinuke = 0, shield = 0, jam = 0, radar = 0, sonar = 0}
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

function TurtleHandler:BestTurtle(builder, unitName, most, bombard)
	if builder == nil then return end
	if unitName == nil then return end
	local position = builder:GetPosition()
	local ut = unitTable[unitName]
	local Metal
	local ground, air, submerged, antinuke, shield, jam
	if most then
		-- if we're looking for the most turtled position, count everything
		ground = true
		air = true
		submerged = true
		antinuke = true
		shield = true
		jam = true
		radar = true
		sonar = true
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
		elseif ut.radarRadius ~= 0 then
			radar = true
		elseif ut.sonarRadius ~= 0 then
			sonar = true
		end
		Metal = game:GetResourceByName("Metal")
	end
	--[[
	local distanceLimit = 1000
	local mtype = unitTable[builder:Name()].mtype
	if mtype == "bot" then
		distanceLimit = 1000
	elseif mtype == "veh" or mtype == "amp" then
		distanceLimit = 2000
	elseif mtype == "hov" then
		distanceLimit = 3000
	elseif mtype == "shp" or mtype == "sub" then
		distanceLimit = 1500
	elseif mtype == "air" then
		distanceLimit = 100000
	end
	local bestMod = 0
	]]--
	local bestDist = 100000
	local best
	for i, turtle in pairs(self.turtles) do
		local isLocal = true
		if ground or air or submerged then
			isLocal = ai.maphandler:CheckDefenseLocalization(unitName, turtle.position)
		end
		if ai.maphandler:UnitCanGoHere(builder, turtle.position) and isLocal then
			local okay = true
			if bombard then 
				okay = ai.targethandler:IsBombardPosition(turtle.position, unitName)
			end
			if okay then
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
				if radar then
					mod = mod + turtle.radar * radarMod
				end
				if sonar then
					mod = mod + turtle.sonar * sonarMod
				end
				local modLimit = (turtle.priority / self.totalPriority) * Metal.income * 80
				modLimit = math.max(100, modLimit)
				if (mod ~= 0 and most) or (mod < modLimit and not most) then
					local dist = distance(position, turtle.position)
					if not most then mod = modLimit - mod end
					mod = mod * distanceMod
					dist = dist - mod
					if dist < bestDist then
						bestDist = dist
						best = turtle.position
					end
					--[[
					if dist < distanceLimit then
						if most then
							if mod > bestMod then
								bestMod = mod
								best = turtle.position
							end
						else
							mod = modLimit - mod
							if mod > bestMod then
								bestMod = mod
								best = turtle.position
							end
						end
					end
					]]--
				end
			end
		end
	end
	return best
end