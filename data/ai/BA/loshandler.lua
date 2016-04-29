
shard_include "common"

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

function LosHandler:Init()
	self.losGrid = {}
	ai.knownEnemies = {}
	ai.knownWrecks = {}
	ai.wreckCount = 0
	ai.enemyList = {}
	ai.blips = {}
	ai.lastLOSUpdate = 0
	ai.friendlyTeamID = {}
	self:Update()
end

function LosHandler:Update()
	local f = game:Frame()

	if f % 23 == 0 then
		if ShardSpringLua and self.ai.alliedTeamIds then
			self.ai.friendlyTeamID = {}
			self.ai.friendlyTeamID[self.game:GetTeamID()] = true
			for teamID, _ in pairs(self.ai.alliedTeamIds) do
				self.ai.friendlyTeamID[teamID] = true
			end
		else
			if DebugEnabled then 
				debugPlotLosFile = assert(io.open("debuglosplot",'w'), "Unable to write debuglosplot")
			end 
			-- game:SendToConsole("updating los")
			self.losGrid = {}
			-- note: this could be more effecient by using a behaviour
			-- if the unit is a building, we know it's LOS contribution forever
			-- if the unit moves, the behaviours can be polled rather than GetFriendlies()
			-- except for allies' units
			local friendlies = game:GetFriendlies()
			ai.friendlyTeamID = {}
			ai.friendlyTeamID[game:GetTeamID()] = true
			if friendlies ~= nil then
				for _, unit in pairs(friendlies) do
					ai.friendlyTeamID[unit:Team()] = true -- because I can't get allies' teamIDs directly
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
		end
		-- update enemy jamming and populate list of enemies
		local enemies = game:GetEnemies()
		if enemies ~= nil then
			local enemyList = {}
			for i, e in pairs(enemies) do
				local uname = e:Name()
				local upos = e:GetPosition()
				if not ShardSpringLua then
					local utable = unitTable[uname]
					if utable.jammerRadius > 0 then
						self:FillCircle(upos.x, upos.z, utable.jammerRadius, 1, true)
					end
				end
				-- so that we only have to poll GetEnemies() once
				table.insert(enemyList, { unitName = uname, position = upos, unitID = e:ID(), cloaked = e:IsCloaked(), beingBuilt = e:IsBeingBuilt(), health = e:GetHealth(), los = 0 })
			end
			-- update known enemies
			self:UpdateEnemies(enemyList)
		end
		-- update known wrecks
		self:UpdateWrecks()
		ai.lastLOSUpdate = f
		if DebugEnabled then debugPlotLosFile:close() end
	end
end

function LosHandler:UpdateEnemies(enemyList)
	if enemyList == nil then return end
	if #enemyList == 0 then return end
	-- game:SendToConsole("updating known enemies")
	local known = {}
	local exists = {}
	for i, e  in pairs(enemyList) do
		local id = e.unitID
		local ename = e.unitName
		local pos = e.position
		exists[id] = pos
		if not e.cloaked then
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
				ai.knownEnemies[id] = e
				e.los = los
			end
			if persist == true then
				if ai.knownEnemies[id] ~= nil then
					if ai.knownEnemies[id].los == 2 then
						known[id] = ai.knownEnemies[id].los
					end
				end
			end
			if los == 1 then
				ai.knownEnemies[id] = e
				e.los = los
				known[id] = los
			end
			if ai.knownEnemies[id] ~= nil and DebugEnabled then
				if known[id] == 2 and ai.knownEnemies[id].los == 2 then PlotDebug(pos.x, pos.z, "known") end
			end
		end
	end
	-- remove unit ghosts outside of radar range and building ghosts if they don't exist
	-- this is cheating a little bit, because dead units outside of sight will automatically be removed
	-- also populate moving blips (whether in radar or in sight) for analysis
	local blips = {}
	local f = game:Frame()
	for id, e in pairs(ai.knownEnemies) do
		if not exists[id] then
			-- enemy died
			if ai.IDsWeAreAttacking[id] then
				ai.attackhandler:TargetDied(ai.IDsWeAreAttacking[id])
			end
			if ai.IDsWeAreRaiding[id] then
				ai.raidhandler:TargetDied(ai.IDsWeAreRaiding[id])
			end
			EchoDebug("enemy " .. e.unitName .. " died!")	
			local mtypes = UnitWeaponMtypeList(e.unitName)
			for i, mtype in pairs(mtypes) do
				ai.raidhandler:NeedMore(mtype)
				ai.attackhandler:NeedLess(mtype)
				if mtype == "air" then ai.bomberhandler:NeedLess() end
			end
			ai.knownEnemies[id] = nil
		elseif not known[id] then
			if not e.ghost then
				e.ghost = { frame = f, position = e.position }
			else
				-- expire ghost
				if f > e.ghost.frame + 600 then
					ai.knownEnemies[id] = nil
				end
			end
		else
			if not unitTable[e.unitName].isBuilding then
				local count = true
				if e.los == 2 then
					-- if we know what kind of unit it is, only count as a potential threat blip if it's a hurty unit
					-- air doesn't count because there are no buildings in the air
					local threatLayers = UnitThreatRangeLayers(e.unitName)
					if threatLayers.ground.threat == 0 and threatLayers.submerged.threat == 0 then
						count = false
					end
				end
				if count then table.insert(blips, e) end
			end
			e.ghost = nil
		end
	end
	-- send blips off for analysis
	ai.tacticalhandler:NewEnemyPositions(blips)
end

function LosHandler:UpdateWrecks()
	local wrecks = game.map:GetMapFeatures()
	if wrecks == nil then
		ai.knownWrecks = {}
		return
	end
	if #wrecks == 0 then
		ai.knownWrecks = {}
		return
	end
	-- game:SendToConsole("updating known wrecks")
	local known = {}
	for i, feature  in pairs(wrecks) do
		if feature ~= nil then
			local featureName = feature:Name()
			-- only count features that aren't geovents and that are known to be reclaimable or guessed to be so
			local okay = false
			if featureName ~= "geovent" then -- don't get geo spots
				if featureTable[featureName] then
					if featureTable[featureName].reclaimable then
						okay = true
					end
				else
					for findString, metalValue in pairs(baseFeatureMetal) do
						if string.find(featureName, findString) then
							okay = true
							break
						end
					end
				end
			end
			if okay then
				local position = feature:GetPosition()
				local los = self:GroundLos(position)
				local id = feature:ID()
				local persist = false
				local wreck = { los = los, featureName = featureName, position = position }
				if los == 0 or los == 1 then
					-- don't remove from knownenemies if it was once seen
					persist = true
				elseif los == 2 then
					known[id] = true
					ai.knownWrecks[id] = wreck
				end
				if persist == true then
					if ai.knownWrecks[id] ~= nil then
						if ai.knownWrecks[id].los == 2 then
							known[id] = true
						end
					end
				end
			end
		end
	end
	ai.wreckCount = 0
	-- remove wreck ghosts that aren't there anymore
	for id, los in pairs(ai.knownWrecks) do
		-- game:SendToConsole("known enemy " .. id .. " " .. los)
		if known[id] == nil then
			-- game:SendToConsole("removed")
			ai.knownWrecks[id] = nil
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
	if ShardSpringLua then
		local LosOrRadar, inLos, inRadar, jammed = Spring.GetPositionLosState(upos.x, upos.y, upos.z, self.ai.allyId)
		if inLos then return 2 end
		if upos.y < 0 then -- underwater
			if inRadar then return 3 end
		end
		if inRadar then return 1 end
		if Spring.IsPosInAirLos(upos.x, upos.y, upos.z, self.ai.allyId) then
			return 4
		else
			return 0
		end
	end
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
	if ShardSpringLua then
		local t = {}
		local LosOrRadar, inLos, inRadar, jammed = Spring.GetPositionLosState(upos.x, upos.y, upos.z, self.ai.allyId)
		if inLos then t[2] = true end
		if inRadar then
			if upos.y < 0 then -- underwater
				t[3] = true
			else
				t[1] = true
			end
		end
		if Spring.IsPosInAirLos(upos.x, upos.y, upos.z, self.ai.allyId) then
			t[4] = true
		end
		return t
	end
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
	if ai.knownEnemies[id] then
		return ai.knownEnemies[id].los
	else
		return 0
	end
end

function LosHandler:IsKnownWreck(feature)
	local id = feature:ID()
	if ai.knownWrecks[id] then
		return ai.knownWrecks[id]
	else
		return 0
	end
end

function LosHandler:GhostPosition(unit)
	local id = unit:ID()
	if ai.knownEnemies[id] then
		if ai.knownEnemies[id].ghost then
			return ai.knownEnemies[id].position
		end
	end
	return nil
end
