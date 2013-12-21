
require "common"

local DebugEnabled = false
local debugPlotLosFile

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("LosHandler: " .. inStr)
	end
end

local function PlotDebug(x, z, label)
	if DebugEnabled then
		if label == nil then label= "nil" end
		local string = math.ceil(x) .. " " .. math.ceil(z) .. " " .. label .. "\n"
		debugPlotLosFile:write(string)
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
			debugPlotLosFile:write(string)
			-- debugSquares[x .. "  " .. z .. " " .. size] = true
		-- end
	end
end

LosHandler = class(Module)

local sqrt = math.sqrt
local losGridElmos = 128
local losGridElmosHalf = losGridElmos / 2
local gridSizeX
local gridSizeZ

local function EmptyLosTable()
	local t = {}
	t[1] = false
	t[2] = false
	t[3] = false
	t[4] = false
	return t
end

function LosHandler:Name()
	return "LosHandler"
end

function LosHandler:internalName()
	return "loshandler"
end

local function WhatUnitHurts(unitName)
	if unitName == nil then return {} end
	if unitName == DummyUnitName then return {} end
	local utable = unitTable[unitName]
	local mtypes = {}
	if utable.groundRange > 0 then
		table.insert(mtypes, "veh")
		table.insert(mtypes, "bot")
		table.insert(mtypes, "amp")
		table.insert(mtypes, "hov")
		table.insert(mtypes, "shp")
	end
	if utable.airRange > 0 then
		table.insert(mtypes, "air")
	end
	if utable.submergedRange > 0 then
		table.insert(mtypes, "sub")
		table.insert(mtypes, "shp")
		table.insert(mtypes, "amp")
	end
	return mtypes
end

function LosHandler:Init()
	self.losGrid = {}
	self.knownEnemies = {}
	self.knownWrecks = {}
	self.ghosts = {}
	self.enemyNames = {}
	ai.wreckCount = 0
	self:Update()
end

function LosHandler:Update()
	local f = game:Frame()

	if math.mod(f,23) == 0 then
		if DebugEnabled then 
			debugPlotLosFile = assert(io.open("debuglosplot",'w'), "Unable to write debuglosplot")
		end 
		-- game:SendToConsole("updating los")
		local ownUnits = game:GetFriendlies()
		if ownUnits == nil then
			ownUnits = {}
		end
		ai.friendlyCount = #ownUnits
		self.losGrid = {}
		ai.friendlyCount = 0
		local ownUnits = game:GetFriendlies()
		if ownUnits ~= nil then
			ai.friendlyCount = table.getn(ownUnits)
			for _, unit in pairs(ownUnits) do
				local uname = unit:Name()
				local utable = unitTable[uname]
				local upos = unit:GetPosition()
				if utable.losRadius > 0 then
					self:FillCircle(upos.x, upos.z, utable.losRadius * 32, 2)
				end
				if utable.airLosRadius > 0 then
					-- 4 will become 2 in IsKnownEnemy
					self:FillCircle(upos.x, upos.z, (utable.losRadius + utable.airLosRadius) * 32, 4)
				end
				if utable.radarRadius > 0 then
					self:FillCircle(upos.x, upos.z, utable.radarRadius, 1)
				end
				if utable.sonarRadius > 0 then
					-- 3 will become 2 in IsKnownEnemy
					self:FillCircle(upos.x, upos.z, utable.sonarRadius, 3)
				end
			end
		end
		-- update enemy jamming
		local enemies = game:GetEnemies()
		if enemies ~= nil then
			for _, e in pairs(enemies) do
				local utable = unitTable[e:Name()]
				if utable.jammerRadius > 0 then
					local upos = e:GetPosition()
					self:FillCircle(upos.x, upos.z, utable.jammerRadius, 1, true)
				end
			end
			-- update known enemies
			self:UpdateEnemies()
		end
		-- update known wrecks
		self:UpdateWrecks()
		if DebugEnabled then debugPlotLosFile:close() end
	end
end

function LosHandler:UpdateEnemies()
	local enemies = game:GetEnemies()
	if enemies == nil then return end
	if #enemies == 0 then return end
	-- game:SendToConsole("updating known enemies")
	local known = {}
	local exists = {}
	if self.knownEnemies == nil then self.knownEnemies = {} end
	for i, e  in pairs(enemies) do
		if e ~= nil then
			local id = e:ID()
			local ename = e:Name()
			self.enemyNames[id] = ename
			local pos = e:GetPosition()
			exists[id] = pos
			if not e:IsCloaked() then
				local lt = self:AllLos(pos)
				local los = 0
				local persist = false
				local underWater = (unitTable[ename].mtype == "sub")
				if underWater then
					if lt[3] then
						-- sonar
						los = 2
					end
				else 
					if lt[1] and not lt[2] and not unitTable[ename].stealth then
						los = 1
					elseif lt[2] then
						los = 2
					elseif lt[4] and unitTable[ename].mtype == "air" then
						-- air los
						los = 2
					end
				end
				if los == 0 and unitTable[ename].isBuilding then
					-- don't remove from knownenemies if it's a building that was once seen
					persist = true
				elseif los == 1 then
					-- don't remove from knownenemies if it's a now blip
					persist = true
				elseif los == 2 then
					known[id] = los
					self.knownEnemies[id] = los
				end
				if persist == true then
					if self.knownEnemies[id] ~= nil then
						if self.knownEnemies[id] == 2 then
							known[id] = self.knownEnemies[id]
						end
					end
				end
				if los == 1 then
					self.knownEnemies[id] = los
					known[id] = los
				end
				if self.knownEnemies[id] ~= nil and DebugEnabled then
					if known[id] == 2 and self.knownEnemies[id] == 2 then PlotDebug(pos.x, pos.z, "known") end
				end
			end
		end
	end
	-- remove unit ghosts outside of radar range and building ghosts if they don't exist
	-- this is cheating a little bit, because dead units outside of sight will automatically be removed
	local f = game:Frame()
	for id, los in pairs(self.knownEnemies) do
		if not exists[id] then
			-- enemy died
			if ai.IDsWeAreAttacking[id] then
				ai.attackhandler:TargetDied(ai.IDsWeAreAttacking[id])
			end
			if ai.IDsWeAreRaiding[id] then
				ai.raidhandler:TargetDied(ai.IDsWeAreRaiding[id])
			end
			local uname = self.enemyNames[id]
			EchoDebug("enemy " .. uname .. " died!")	
			local mtypes = WhatUnitHurts(uname)
			for i, mtype in pairs(mtypes) do
				ai.raidhandler:NeedMore(mtype)
				ai.attackhandler:NeedLess(mtype)
				if mtype == "air" then ai.bomberhandler:NeedLess() end
			end
			self.knownEnemies[id] = nil
			self.ghosts[id] = nil
		elseif not known[id] then			
			self.knownEnemies[id] = nil
			if not self.ghosts[id] then
				self.ghosts[id] = { frame = f, position = exists[id] }
			end
		else
			self.ghosts[id] = nil
		end
	end
	-- expire ghosts
	for id, g in pairs(self.ghosts) do
		if f > g.frame + 900 then
			self.ghosts[id] = nil
		end
	end
end

function LosHandler:UpdateWrecks()
	local wrecks = game.map:GetMapFeatures()
	if wrecks == nil then return end
	if #wrecks == 0 then return end
	-- game:SendToConsole("updating known wrecks")
	local known = {}
	if self.knownWrecks == nil then self.knownWrecks = {} end
	for i, w  in pairs(wrecks) do
		if w ~= nil then
			local wname = w:Name()
			-- only count features that aren't geovents and that are known to be reclaimable or guessed to be so
			local okay = false
			if wname ~= "geovent" then
				if featureTable[wname] then
					if featureTable[wname].reclaimable then
						okay = true
					end
				else
					for findString, metalValue in pairs(baseFeatureMetal) do
						if string.find(wname, findString) then
							okay = true
							break
						end
					end
				end
			end
			if okay then
				-- don't get geo spots
				local pos = w:GetPosition()
				local los = self:GroundLos(pos)
				local id = w:ID()
				local persist = false
				if los == 0 or los == 1 then
					-- don't remove from knownenemies if it was once seen
					persist = true
				elseif los == 2 then
					known[id] = los
					self.knownWrecks[id] = los
				end
				if persist == true then
					if self.knownWrecks[id] ~= nil then
						if self.knownWrecks[id] == 2 then
							known[id] = self.knownWrecks[id]
						end
					end
				end
			end
		end
	end
	ai.wreckCount = 0
	-- remove wreck ghosts that aren't there anymore
	for id, los in pairs(self.knownWrecks) do
		-- game:SendToConsole("known enemy " .. id .. " " .. los)
		if known[id] == nil then
			-- game:SendToConsole("removed")
			self.knownWrecks[id] = nil
		else
			ai.wreckCount = ai.wreckCount + 1
		end
	end
	-- cleanup
	known = {}
end

function LosHandler:HorizontalLine(x, z, tx, val, jam)
	-- EchoDebug("horizontal line from " .. x .. " to " .. tx .. " along z " .. z .. " with value " .. val)
	for ix = x, tx do
		if jam then
			if self.losGrid[ix] == nil then return end
			if self.losGrid[ix][z] == nil then return end
			if DebugEnabled then
				if self.losGrid[ix][z][val] == true then PlotSquareDebug(ix * losGridElmos, z * losGridElmos, losGridElmos, "JAM") end
			end
			if self.losGrid[ix][z][val] then self.losGrid[ix][z][val] = false end
		else
			if self.losGrid[ix] == nil then self.losGrid[ix] = {} end
			if self.losGrid[ix][z] == nil then
				self.losGrid[ix][z] = EmptyLosTable()
			end
			if self.losGrid[ix][z][val] == false and DebugEnabled then PlotSquareDebug(ix * losGridElmos, z * losGridElmos, losGridElmos, val) end
			self.losGrid[ix][z][val] = true
		end
	end
end

function LosHandler:Plot4(cx, cz, x, z, val, jam)
	self:HorizontalLine(cx - x, cz + z, cx + x, val, jam)
	if x ~= 0 and z ~= 0 then
        self:HorizontalLine(cx - x, cz - z, cx + x, val, jam)
    end
end 

function LosHandler:FillCircle(cx, cz, radius, val, jam)
	-- convert to grid coordinates
	cx = math.ceil(cx / losGridElmos)
	cz = math.ceil(cz / losGridElmos)
	radius = math.floor(radius / losGridElmos)
	if radius > 0 then
		local err = -radius
		local x = radius
		local z = 0
		while x >= z do
	        local lastZ = z
	        err = err + z
	        z = z + 1
	        err = err + z
	        self:Plot4(cx, cz, x, lastZ, val, jam)
	        if err >= 0 then
	            if x ~= lastZ then self:Plot4(cx, cz, lastZ, x, val, jam) end
	            err = err - x
	            x = x - 1
	            err = err - x
	        end
	    end
	end
end

function LosHandler:GroundLos(upos)
	local gx = math.ceil(upos.x / losGridElmos)
	local gz = math.ceil(upos.z / losGridElmos)
	if self.losGrid[gx] == nil then
		return 0
	elseif self.losGrid[gx][gz] == nil then
		return 0
	else
		if ai.maphandler:IsUnderWater(upos) then
			if self.losGrid[gx][gz][3] then
				return 3
			else
				return 0
			end
		elseif self.losGrid[gx][gz][1] and not self.losGrid[gx][gz][2] then
			return 1
		elseif self.losGrid[gx][gz][2] then
			return 2
		else
			return 0
		end
	end
end

function LosHandler:AllLos(upos)
	local gx = math.ceil(upos.x / losGridElmos)
	local gz = math.ceil(upos.z / losGridElmos)
	if self.losGrid[gx] == nil then
		return EmptyLosTable()
	elseif self.losGrid[gx][gz] == nil then
		return EmptyLosTable()
	else
		return self.losGrid[gx][gz]
	end
end

function LosHandler:IsKnownEnemy(unit)
	local id = unit:ID()
	if self.knownEnemies[id] then
		return self.knownEnemies[id]
	else
		return 0
	end
end

function LosHandler:IsKnownWreck(feature)
	local id = feature:ID()
	if self.knownWrecks[id] then
		return self.knownWrecks[id]
	else
		return 0
	end
end

function LosHandler:GhostPosition(unit)
	local id = unit:ID()
	if self.ghosts[id] then
		return self.ghosts[id].position
	else
		return nil
	end
end
