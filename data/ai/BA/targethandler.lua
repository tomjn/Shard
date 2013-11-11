require "unittable"
require "unitlists"

local DebugEnabled = false
local debugPlotTargetFile

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("TargetHandler: " .. inStr)
	end
end

local function PlotDebug(x, z, label)
	if DebugEnabled then
		if label == nil then label= "nil" end
		local string = math.ceil(x) .. " " .. math.ceil(z) .. " " .. label .. "\n"
		debugPlotTargetFile:write(string)
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
			debugPlotTargetFile:write(string)
			-- debugSquares[x .. "  " .. z .. " " .. size] = true
		-- end
	end
end

TargetHandler = class(Module)

local sqrt = math.sqrt
local fmod = math.fmod
local floor = math.floor
local ceil = math.ceil
local mod = math.mod

local function round(num) 
	if num >= 0 then
		return floor(num+.5) 
	else
		return ceil(num-.5)
	end
end

local function dist2d(x1, z1, x2, z2)
	local xd = x1 - x2
	local yd = z1 - z2
	local dist = sqrt(xd*xd + yd*yd)
	return dist
end

local cellElmos = 256
local cellElmosHalf = cellElmos / 2
local threatTypes = { "ground", "air", "submerged" }
local baseUnitThreat = 150
local baseUnitRange = 250
local baseBuildingValue = 150
local bomberExplosionValue = 2000
local vulnerableHealth = 200
local wreckMult = 100
local badCellThreat = 300

local feintRepeatMod = 10

local cellElmosX
local cellElmosZ
local cells = {}
local cellList = {}
local cell
local badPositions = {}

local lastUpdateFrame = 0

local function NewCell(px, pz)
	local newcell = {value = 0, groundValue = 0, airValue = 0, submergedValue = 0, bomberValue = 0, groundThreat = 0, airThreat = 0, submergedThreat = 0, bomberTargets = {}, wrecks = 0, friendlyValue = 0, friendlyBuildings = 0, friendlyLandCombats = 0, friendlyAirCombats = 0, friendlyWaterCombats = 0, x = px, z = pz}
	return newcell
end

local function ThreatRange(unitName, groundAirSubmerged)
	local utable = unitTable[unitName]
	if groundAirSubmerged == nil then
		if utable.groundRange > utable.airRange and utable.groundRange > utable.submergedRange then
			groundAirSubmerged = "ground"
		elseif utable.airRange > utable.groundRange and utable.airRange > utable.submergedRange then
			groundAirSubmerged = "air"
		elseif utable.submergedRange > utable.groundRange and utable.submergedRange > utable.airRange then
			groundAirSubmerged = "submerged"
		end
	end
	local threat = 0
	local range = 0
	if groundAirSubmerged == "ground" then
		range = utable.groundRange
	elseif groundAirSubmerged == "air" then
		range = utable.airRange
		if range == 0 then
			-- ground weapons can hurt air units sometimes
			if utable.groundRange > 0 then
				return math.ceil(utable.metalCost * 0.33), utable.groundRange
			end
		end
	elseif groundAirSubmerged == "submerged" then
		range = utable.submergedRange
	end
	if range > 0 and threat == 0 then
		threat = utable.metalCost
	end
	-- double the threat if it's a building (buildings are more bang for your buck)
	if threat > 0 and utable.isBuilding then threat = threat + threat end
	return threat, range
end

local function Value(unitName)
	local utable = unitTable[unitName]
	if not utable then return 0 end
	local val = utable.metalCost
	if utable.buildOptions ~= nil then
		if utable.isBuilding then
			-- factory
			val = val + 1000
		else
			-- construction unit
			val = val + 300
		end
	end
	if utable.extractsMetal > 0 then
		val = val + 1000000 * utable.extractsMetal
	end
	if utable.totalEnergyOut > 0 then
		val = val + utable.totalEnergyOut
	end
	return val
end

local function WhatHurtsUnit(unit, mtype)
	if unit ~= nil then 
		mtype = unitTable[unit:Name()].mtype
	end
	local hurts = {}
	if mtype == "veh" or mtype == "bot" or mtype == "amp" or mtype == "hov" or mtype == "shp" then
		hurts["ground"] = true
	end
	if mtype == "air" then
		hurts["air"] = true
	end
	if mtype == "sub" or mtype == "shp" or mtype == "amp" then
		hurts["submerged"] = true
	end
	return hurts
end

--[[
local function WhereUnitGoes(unit)
	local mtype = unitTable[unit:Name()].mtype
	local law = {}
	if mtype == "veh" or mtype == "bot" or mtype == "hov" or mtype == "amp" then
		law["land"] = true
	end
	if mtype == "air" then
		law["air"] = true
	end
	if mtype == "sub" or mtype == "shp" or mtype == "hov" or mtype == "amp" then
		law["water"] = true
	end
	return law
end
]]--

local function CellValueThreat(unit, cell)
	if cell == nil then return 0, 0 end
	local gas
	local name
	if unit == "ALL" then
		gas = {}
		gas["ground"] = true
		gas["air"] = true
		gas["submerged"] = true
		name = "nothing"
	else
		gas = WhatHurtsUnit(unit)
		name = unit:Name()
	end
	local threat = 0
	local value = 0
	if gas["ground"] then
		threat = threat + cell.groundThreat
		value = value + cell.groundValue
	end
	if gas["air"] then
		threat = threat + cell.airThreat
		value = value + cell.airValue
	end
	if gas["submerged"] then
		threat = threat + cell.submergedThreat
		value = value + cell.submergedValue
	end
	if raiderDisarms[name] then
		local notThreat = 0
		if not gas["ground"] then notThreat = notThreat + cell.groundThreat end
		if not gas["air"] then notThreat = notThreat + cell.airThreat end
		if not gas["submerged"] then notThreat = notThreat + cell.submergedThreat end
		if notThreat == 0 then
			value = 0
		end
	end
	return value, threat, gas
end

local function GetCellPosition(pos)
	local px = ceil(pos.x / cellElmos)
	local pz = ceil(pos.z / cellElmos)
	return px, pz
end

local function GetCellHere(pos)
	local px, pz = GetCellPosition(pos)
	if cells[px] then
		return cells[px][pz]
	end
end

function TargetHandler:Name()
	return "TargetHandler"
end

function TargetHandler:internalName()
	return "targethandler"
end

local function HorizontalLine(x, z, tx, groundAirSubmerged, val)
	-- EchoDebug("horizontal line from " .. x .. " to " .. tx .. " along z " .. z .. " with value " .. val .. " in " .. groundAirSubmerged)
	for ix = x, tx do
		if cells[ix] == nil then cells[ix] = {} end
		if cells[ix][z] == nil then
			-- EchoDebug("new cell" .. ix .. "," .. z)
			cells[ix][z] = NewCell(ix, z)
			if DebugEnabled then table.insert(cellList, cells[ix][z]) end
		end
		if groundAirSubmerged == "ground" then
			cells[ix][z].groundThreat = cells[ix][z].groundThreat + val
		elseif groundAirSubmerged == "air" then
			cells[ix][z].airThreat = cells[ix][z].airThreat + val
		elseif groundAirSubmerged == "submerged" then
			cells[ix][z].submergedThreat = cells[ix][z].submergedThreat + val
		end
	end
end

local function Plot4(cx, cz, x, z, groundAirSubmerged, val)
	HorizontalLine(cx - x, cz + z, cx + x, groundAirSubmerged, val)
	if x ~= 0 and z ~= 0 then
        HorizontalLine(cx - x, cz - z, cx + x, groundAirSubmerged, val)
    end
end 

local function FillCircle(cx, cz, radius, groundAirSubmerged, val)
	local radius = math.ceil(radius / cellElmos)
	if radius > 0 then
		local err = -radius
		local x = radius
		local z = 0
		while x >= z do
	        local lastZ = z
	        err = err + z
	        z = z + 1
	        err = err + z
	        Plot4(cx, cz, x, lastZ, groundAirSubmerged, val)
	        if err >= 0 then
	            if x ~= lastZ then Plot4(cx, cz, lastZ, x, groundAirSubmerged, val) end
	            err = err - x
	            x = x - 1
	            err = err - x
	        end
	    end
	end
end

local function CheckHorizontalLine(x, z, tx, groundAirSubmerged)
	-- EchoDebug("horizontal line from " .. x .. " to " .. tx .. " along z " .. z .. " in " .. groundAirSubmerged)
	local value = 0
	local threat = 0
	for ix = x, tx do
		if cells[ix] ~= nil then
			if cells[ix][z] ~= nil then
				if groundAirSubmerged == "ground" then
					value = value + cells[ix][z].groundValue
					threat = threat + cells[ix][z].groundThreat
				elseif groundAirSubmerged == "air" then
					value = value + cells[ix][z].airValue
					threat = threat + cells[ix][z].airThreat
				elseif groundAirSubmerged == "submerged" then
					value = value + cells[ix][z].submergedValue
					threat = threat + cells[ix][z].submergedThreat
				end
			end
		end
	end
	return value, threat
end

local function Check4(cx, cz, x, z, groundAirSubmerged)
	local value = 0
	local threat = 0
	local v, t = CheckHorizontalLine(cx - x, cz + z, cx + x, groundAirSubmerged)
	value = value + v
	threat = threat + t
	if x ~= 0 and z ~= 0 then
        local v, t = CheckHorizontalLine(cx - x, cz - z, cx + x, groundAirSubmerged)
        value = value + v
        threat = threat + t
    end
    return value, threat
end 

local function CheckInRadius(cx, cz, radius, groundAirSubmerged)
	local radius = math.ceil(radius / cellElmos)
	local value = 0
	local threat = 0
	if radius > 0 then
		local err = -radius
		local x = radius
		local z = 0
		while x >= z do
	        local lastZ = z
	        err = err + z
	        z = z + 1
	        err = err + z
	        local v, t = Check4(cx, cz, x, lastZ, groundAirSubmerged)
	        value = value + v
	        threat = threat + t
	        if err >= 0 then
	            if x ~= lastZ then
	            	local v, t = Check4(cx, cz, lastZ, x, groundAirSubmerged)
	            	value = value + v
	       			threat = threat + t
	            end
	            err = err - x
	            x = x - 1
	            err = err - x
	        end
	    end
	end
	return value, threat
end

local function CountEnemyThreat(e, threat)
	if not enemyAlreadyCounted[e] then
		currentEnemyThreatCount = currentEnemyThreatCount + threat
		enemyAlreadyCounted[e] = true
	end
end

local function UpdateEnemies()
	local enemies = game:GetEnemies()
	if enemies == nil then return end
	if #enemies == 0 then return end

	-- figure out where all the enemies are!
	local highestValue = 0
	local highestValueCell
	for i, e in pairs(enemies) do
		local los = ai.loshandler:IsKnownEnemy(e)
		local ghost = ai.loshandler:GhostPosition(e)
		local name = e:Name()
		if los ~= 0 or ghost then
			local pos
			if ghost then
				EchoDebug("using ghost position")
				pos = ghost 
			else
				pos = e:GetPosition()
			end
			local px, pz = GetCellPosition(pos)
			if cells[px] == nil then
				cells[px] = {}
			end
			if cells[px][pz] == nil then
				cells[px][pz] = NewCell(px, pz)
				table.insert(cellList, cells[px][pz])
			end
			cell = cells[px][pz]
			if los == 1 then
				if unitTable[name].isBuilding then
					cell.value = cell.value + baseBuildingValue
				else
					-- if it moves, assume it's out to get you
					FillCircle(px, pz, baseUnitRange, "ground", baseUnitThreat)
					FillCircle(px, pz, baseUnitRange, "air", baseUnitThreat)
					FillCircle(px, pz, baseUnitRange, "submerged", baseUnitThreat)
				end
			elseif los == 2 then
				local value = Value(name)
				for i, groundAirSubmerged in pairs(threatTypes) do
					local threat, range = ThreatRange(name, groundAirSubmerged)
					-- EchoDebug(name .. " " .. groundAirSubmerged .. " " .. threat .. " " .. range)
					if threat ~= 0 then
						FillCircle(px, pz, range, groundAirSubmerged, threat)
						CountEnemyThreat(e, threat)
					elseif not unitsToIgnoreAsAttackTarget[name] then
						-- for those times when you need to attack the unit itself, not the ground
						local health = e:GetHealth()
						local mtype = unitTable[name].mtype
						if groundAirSubmerged == "ground" then
							if mtype ~= "air" and mtype ~= "sub" then
								cell.groundTarget = e
								if health < vulnerableHealth then
									cell.groundVulnerable = e
								end
								cell.groundValue = cell.groundValue + value
							end
						elseif groundAirSubmerged == "air" then
							if mtype ~= "sub" and mtype ~= "air" then
								cell.airTarget = e
								table.insert(cell.bomberTargets, e)
								if health < vulnerableHealth then
									cell.airVulnerable = e
								end
								cell.airValue = cell.airValue + value
								cell.bomberValue = cell.bomberValue + value
								if unitTable[name].bigExplosion then cell.bomberValue = cell.bomberValue + bomberExplosionValue end
							end
						elseif groundAirSubmerged == "submerged" then
							if mtype == "sub" or mtype == "shp" then
								cell.submergedTarget = e
								if health < vulnerableHealth then
									cell.submergedVulnerable = e
								end
								cell.submergedValue = cell.submergedValue + value
							end
						end
					end
				end
				cell.value = cell.value + value
				if cell.value > highestValue then
					highestValue = cell.value
					highestValueCell = cell
				end
			end
			
			-- we dont want to target the center of the cell encase its a ledge with nothing
			-- on it etc so target this units position instead
			cell.pos = pos
		end
	end
	if highestValueCell then
		ai.enemyBasePosition = highestValueCell.pos
	end
end

--[[
local function UpdateFriendlies()
	ai.totalFriendlyThreat = 0
	local friendlies = game:GetFriendlies()
	if friendlies == nil then return end
	if #friendlies == 0 then return end
	-- figure out where all the friendlies are!
	for i, f in pairs(friendlies) do
		local name = f:Name()
		local pos = f:GetPosition()
		local px, pz = GetCellPosition(pos)
		if cells[px] == nil then
			cells[px] = {}
		end
		if cells[px][pz] == nil then
			cells[px][pz] = NewCell(px, pz)
			table.insert(cellList, cells[px][pz])
		end
		cell = cells[px][pz]
		cell.friendlyValue = cell.friendlyValue + Value(name)
		if unitTable[name].isBuilding then
			cell.friendlyBuildings = cell.friendlyBuildings + 1
		end
		local threat, range = ThreatRange(name)
		-- EchoDebug(name .. " " .. groundAirSubmerged .. " " .. threat .. " " .. range)
		if threat ~= 0 then
			ai.totalFriendlyThreat = ai.totalFriendlyThreat + threat
			if not unitTable[name].isBuilding then
				local mtype = unitTable[name].mtype
				-- count mobile combat units in cell
				if mtype == "veh" or mtype == "bot" or mtype == "hov" or mtype == "amp" then
					cell.friendlyLandCombats = cell.friendlyLandCombats + 1
				end
				if mtype == "air" then
					cell.friendlyAirCombats = cell.friendlyAirCombats + 1
				end
				if mtype == "sub" or mtype == "shp" or mtype == "hov" or mtype == "amp" then
					cell.friendlyWaterCombats = cell.friendlyWaterCombats + 1
				end
			end
		end
		if cell.pos == nil then cell.pos = pos end
	end
end
]]--

local function UpdateBadPositions()
	local f = game:Frame()
	-- game:SendToConsole(f .. ": " .. #badPositions .. " bad positions before")
	for i, r in pairs(badPositions) do
		if cells[r.px] then
			cell = cells[r.px][r.pz]
			if cell then
				if r.groundAirSubmerged == "ground" then
					cell.groundThreat = cell.groundThreat + badCellThreat
				elseif r.groundAirSubmerged == "air" then
					cell.airThreat = cell.airThreat + badCellThreat
				elseif  r.groundAirSubmerged == "submerged" then
					cell.submergedThreat = cell.submergedThreat + badCellThreat
				end
			end
		end
		if f > r.frame + 1800 then
			-- remove bad positions after 1 minute
			table.remove(badPositions, i)
			-- game:SendToConsole("bad position #" .. i .. " removed")
		end
	end
	-- game:SendToConsole(f .. ": " .. #badPositions .. " bad positions after")
end

local function UpdateWrecks()
	-- figure out where all the wrecks are
	local wrecks = map:GetMapFeatures()
	if wrecks == nil then return end
	if #wrecks == 0 then return end
	for i, w in pairs(wrecks) do
		if ai.loshandler:IsKnownWreck(w) then
			-- will need to check if reclaimer can get to wreck later
			-- ai.maphandler:UnitCanGoHere(representative, pos)
			local pos = w:GetPosition()
			-- EchoDebug("wreck position" .. pos.x .. " " .. pos.z)
			local px, pz = GetCellPosition(pos)
			if cells[px] == nil then
				cells[px] = {}
			end
			if cells[px][pz] == nil then
				cells[px][pz] = NewCell(px, pz)
				table.insert(cellList, cells[px][pz])
			end
			cell = cells[px][pz]
			cell.wrecks = cell.wrecks + 1 
			if cell.pos == nil then
				cell.pos = pos
			end
			if cell.wreckTarget == nil then
				cell.wreckTarget = w
			end
		end
	end
end

local function UpdateDebug()
	if DebugEnabled then 
		debugPlotTargetFile = assert(io.open("debugtargetplot",'w'), "Unable to write debugtargetplot")
		for i, cell in pairs(cellList) do
			local x = cell.x * cellElmos - cellElmosHalf
			local z = cell.z * cellElmos - cellElmosHalf
			PlotSquareDebug(x, z, cellElmos, tostring(cell.value))
			local threat = cell.groundThreat + cell.airThreat + cell.submergedThreat
			PlotSquareDebug(x, z, cellElmos, tostring(-threat))
		end
		debugPlotTargetFile:close()
	end
end

function TargetHandler:Init()
	currentEnemyThreatCount = 0
	enemyAlreadyCounted = {}
	ai.totalEnemyThreat = 10000
	self.feints = {}
end

function TargetHandler:Update()
	local f = game:Frame()
	if f % 1800 == 0 then
		-- store and reset the threat count
		-- EchoDebug(currentEnemyThreatCount .. " enemy threat last 2000 frames")
		EchoDebug(currentEnemyThreatCount)
		ai.totalEnemyThreat = currentEnemyThreatCount
		currentEnemyThreatCount = 0
		enemyAlreadyCounted = {}
	end
end

function TargetHandler:AddBadPosition(position, mtype)
	local px, pz = GetCellPosition(position)
	local gas = WhatHurtsUnit(nil, mtype)
	local f = game:Frame()
	for groundAirSubmerged, yes in pairs(gas) do
		if yes then
			local newRecord =
			{
				px = px,
				pz = pz,
				groundAirsSubmerged = groundAirSubmerged,
				frame = f,
			}
			table.insert(badPositions, newRecord)
		end
	end
end

function TargetHandler:UpdateMap()
	local f = game:Frame()
	if f > lastUpdateFrame + 30 then
		cells = {}
		cellList = {}
		UpdateEnemies()
		-- UpdateFriendlies()
		UpdateBadPositions()
		UpdateWrecks()
		UpdateDebug()
		lastUpdateFrame = f
	end
end

local function CellVulnerable(cell, gas)
	if cell == nil then return end
	-- check this cell
	local vulnerable = nil
	if not gas["ground"] and cell.groundVulnerable and cell.groundThreat == 0 then
		vulnerable = cell.groundVulnerable
	end
	if vulnerable == nil and not gas["air"] and cell.airVulnerable and cell.airThreat == 0 then
		vulnerable = cell.airVulnerable
	end
	if vulnerable == nil and not gas["submerged"] and cell.submergedVulnerable and cell.submergedThreat == 0 then
		vulnerable = cell.submergedVulnerable
	end
	return vulnerable
end

function TargetHandler:NearbyVulnerable(unit)
	if unit == nil then return end
	self:UpdateMap()
	local px, pz = GetCellPosition(unit:GetPosition())
	local gas = WhatHurtsUnit(unit)
	-- check this cell
	local vulnerable = nil
	if cells[px] ~= nil then
		if cells[px][pz] ~= nil then
			vulnerable = CellVulnerable(cells[px][pz], gas)
		end
	end
	-- check adjacent cells
	if vulnerable == nil then
		for ix = px - 1, px + 1 do
			for iz = pz - 1, pz + 1 do
				if cells[ix] ~= nil then
					if cells[ix][iz] ~= nil then
						vulnerable = CellVulnerable(cells[ix][iz], gas)
						if vulnerable then break end
					end
				end
			end
			if vulnerable then break end
		end
	end
	return vulnerable
end

function TargetHandler:GetBestRaidCell(representative)
	if not representative then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local rname = representative:Name()
	local maxThreat = baseUnitThreat
	local rthreat, rrange = ThreatRange(rname)
	EchoDebug(rname .. ": " .. rthreat .. " " .. rrange)
	if rthreat > maxThreat then maxThreat = rthreat end
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(representative, cell)
		-- EchoDebug(value .. " " .. threat)
		if value > 0 and threat <= maxThreat then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				local mod = value - (threat * 3)
				local dist = distance(rpos, cell.pos) - mod
				if dist < bestDist then
					best = cell
					bestDist = dist
				end
			end
		end
	end
	return best
end

function TargetHandler:GetBestAttackCell(representative)
	if not representative then return end
	self:UpdateMap()
	local best
	local bestValue = -999999
	local name = representative:Name()
	local longrange = unitTable[name].groundRange > 650
	local mtype = unitTable[name].mtype
	if mtype ~= "sub" and longrange then longrange = true end
	for i, cell in pairs(cellList) do
		if cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) or longrange then
				local value, threat = CellValueThreat(representative, cell)
				if value > 0 or threat > 0 then
					value = value - threat
					if value > bestValue then
						best = cell
						bestValue = value
					end
				end
			end
		end
	end
	return best
end

function TargetHandler:GetBestNukeCell()
	self:UpdateMap()
	local best
	local bestValueThreat = 0
	for i, cell in pairs(cellList) do
		if cell.pos then
			local value, threat = CellValueThreat("ALL", cell)
			local valuethreat = value + threat
			if valuethreat > bestValueThreat then
				best = cell
				bestValueThreat = valuethreat
			end
		end
	end
	return best, bestValueThreat
end

function TargetHandler:GetBestBomberTarget()
	self:UpdateMap()
	local best
	local bestValue = 0
	for i, cell in pairs(cellList) do
		local value = cell.airValue
		if value > 0 then
			value = value - cell.airThreat
			if value > bestValue then
				best = cell
				bestValue = value
			end
		end
	end
	if best then
		local bestTarget
		bestValue = 0
		for i, e in pairs(best.bomberTargets) do
			local name = e:Name()
			local value = Value(name)
			if name then
				if unitTable[name] then
					if unitTable[name].bigExplosion then value = value + bomberExplosionValue end
				end
			end
			if value > bestValue then
				bestTarget = e
				bestValue = value
			end
		end
		return bestTarget
	end
end

function TargetHandler:GetBestReclaimCell(representative)
	if not representative then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(representative, cell)
		if threat == 0 and cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				local dist = distance(rpos, cell.pos) - (cell.wrecks * wreckMult)
				if dist < bestDist then
					best = cell
					bestDist = dist
				end
			end
		end
	end
	return best
end

function TargetHandler:IsBombardPosition(position, unitName)
	self:UpdateMap()
	local px, pz = GetCellPosition(position)
	local radius = unitTable[unitName].groundRange
	local groundValue, groundThreat = CheckInRadius(px, pz, radius, "ground")
	if groundValue + groundThreat > Value(unitName) * 4 then
		return true
	else
		return false
	end
end

function TargetHandler:IsSafePosition(position, unit)
	self:UpdateMap()
	local cell = GetCellHere(position)
	local value, threat = CellValueThreat(unit, cell)
	if threat == 0 then
		return true
	else
		return false
	end
end

-- for on-the-fly enemy evasion
function TargetHandler:BestAdjacentPosition(unit, targetPosition)
	local position = unit:GetPosition()
	local px, pz = GetCellPosition(position)
	local tx, tz = GetCellPosition(targetPosition)
	if px == tx and pz == tz then
		-- if we're already in the target cell
		return nil, true
	end
	self:UpdateMap()
	local bestDist = 20000
	local best
	local notsafe = false
	local uname = unit:Name()
	local f = game:Frame()
	local maxThreat = baseUnitThreat
	local uthreat, urange = ThreatRange(uname)
	EchoDebug(uname .. ": " .. uthreat .. " " .. urange)
	if uthreat > maxThreat then maxThreat = uthreat end
	for x = px - 1, px + 1 do
		for z = pz - 1, pz + 1 do
			if px == tx and pz == tz then
				-- if we're adjacent to the target cell
				return nil, true
			end
			local dist = dist2d(tx, tz, x, z)
			if cells[x] ~= nil then
				if cells[x][z] ~= nil then
					local value, threat = CellValueThreat(unit, cells[x][z])
					if threat > maxThreat then
						-- if it's below baseUnitThreat, it's probably a lone construction unit
						dist = dist + threat
						notsafe = true
					end
				end
			end
			-- if we just went to the same place, probably not a great place
			for i, feint in pairs(self.feints) do
				if f > feint.frame + 900 then
					-- expire stored after 30 seconds
					table.remove(self.feints, i)
				elseif feint.x == x and feint.z == z and feint.px == px and feint.pz == pz and feint.tx == tx and feint.tz == tz then
					dist = dist + feintRepeatMod
				end
			end
			if dist < bestDist then
				bestDist = dist
				if cells[x] == nil then cells[x] = {} end
				if cells[x][z] == nil then
					cells[x][z] = NewCell(x, z)
				end
				if cells[x][z].pos == nil then
					cells[x][z].pos = api.Position()
					cells[x][z].pos.x = x * cellElmos - cellElmosHalf
					cells[x][z].pos.z = z * cellElmos - cellElmosHalf
					cells[x][z].pos.y = 0
				end
				if ai.maphandler:UnitCanGoHere(unit, cells[x][z].pos) then
					best = cells[x][z]
				end
			end
		end
	end
	if best and notsafe then
		table.insert(self.feints, {x = best.x, z = best.z, px = px, pz = pz, tx = tx, tz = tz, frame = f})
		return best.pos
	end
end