
shard_include "common"

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
local floor = math.floor
local ceil = math.ceil

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
local vulnerableReclaimDistMod = 100
local badCellThreat = 300
local attackDistMult = 0.5 -- between 0 and 1, the lower number, the less distance matters

local factoryValue = 1000
local conValue = 300
local techValue = 50
local energyOutValue = 2
local minNukeValue = factoryValue + techValue + 500

local feintRepeatMod = 25

local unitValue = {}

local enemyAlreadyCounted = {}
local currentEnemyThreatCount = 0
local currentEnemyImmobileThreatCount = 0
local currentEnemyMobileThreatCount = 0

local enemyBaseCell

local cellElmosX
local cellElmosZ
local cells = {}
local cellList = {}
local cell
local badPositions = {}

local dangers = {}

local function NewCell(px, pz)
	local values = {
	ground = {ground = 0, air = 0, submerged = 0, value = 0},
	air = {ground = 0, air = 0, submerged = 0, value = 0},
	submerged = {ground = 0, air = 0, submerged = 0, value = 0},
	} -- value to our units first to who can be hurt by those things, then to those who have those kinds of weapons
	-- [GAS].value is just everything that doesn't hurt that kind of thing 
	local targets = { ground = {}, air = {}, submerged = {}, } -- just one target for each [GAS][hurtGAS]
	local vulnerables = { ground = {}, air = {}, submerged = {}, } -- just one vulnerable for each [GAS][hurtGAS]
	local threat = { ground = 0, air = 0, submerged = 0 } -- threats (including buildings) by what they hurt
	local response = { ground = 0, air = 0, submerged = 0 } -- count mobile threat by what can hurt it
	local preresponse = { ground = 0, air = 0, submerged = 0 } -- count where mobile threat will probably be by what can hurt it 
	local newcell = { value = 0, explosionValue = 0, values = values, threat = threat, response = response, buildingIDs = {}, targets = targets, vulnerables = vulnerables, resurrectables = {}, lastDisarmThreat = 0, metal = 0, energy = 0, x = px, z = pz }
	return newcell
end

local function Value(unitName)
	local v = unitValue[unitName]
	if v then return v end
	local utable = unitTable[unitName]
	if not utable then return 0 end
	local val = utable.metalCost + (utable.techLevel * techValue)
	if utable.buildOptions ~= nil then
		if utable.isBuilding then
			-- factory
			val = val + factoryValue
		else
			-- construction unit
			val = val + conValue
		end
	end
	if utable.extractsMetal > 0 then
		val = val + 800000 * utable.extractsMetal
	end
	if utable.totalEnergyOut > 0 then
		val = val + (utable.totalEnergyOut * energyOutValue)
	end
	unitValue[unitName] = val
	return val
end

-- need to change because: amphibs can't be hurt by non-submerged threats in water, and can't be hurt by anything but ground on land
local function CellValueThreat(unitName, cell)
	if cell == nil then return 0, 0 end
	local gas, weapons
	if unitName == "ALL" then
		gas = { ground = true, air = true, submerged = true }
		weapons = { "ground", "air", "submerged" }
		unitName = "nothing"
	else
		gas = WhatHurtsUnit(unitName, nil, cell.pos)
		weapons = UnitWeaponLayerList(unitName)
	end
	local threat = 0
	local value = 0
	local notThreat = 0
	for GAS, yes in pairs(gas) do
		if yes then
			threat = threat + cell.threat[GAS]
			for i, weaponGAS in pairs(weapons) do
				value = value + cell.values[GAS][weaponGAS]
			end
		elseif raiderDisarms[unitName] then
			notThreat = notThreat + cell.threat[GAS]
		end
	end
	if gas.air and raiderList[unitName] and not raiderDisarms[unitName] then
		threat = threat + cell.threat.ground * 0.1
	end
	if raiderDisarms[unitName] then
		if notThreat == 0 then value = 0 end
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

local function GetOrCreateCellHere(pos)
	local px, pz = GetCellPosition(pos)
	if cells[px] == nil then cells[px] = {} end
	if cells[px][pz] == nil then
		local cell = NewCell(px, pz)
		cell.pos = pos
		cells[px][pz] = cell
		table.insert(cellList, cell)
		return cell
	end
	return cells[px][pz]
end

function TargetHandler:Name()
	return "TargetHandler"
end

function TargetHandler:internalName()
	return "targethandler"
end

local function HorizontalLine(x, z, tx, threatResponse, groundAirSubmerged, val)
	-- EchoDebug("horizontal line from " .. x .. " to " .. tx .. " along z " .. z .. " with value " .. val .. " in " .. groundAirSubmerged)
	for ix = x, tx do
		if cells[ix] == nil then cells[ix] = {} end
		if cells[ix][z] == nil then
			-- EchoDebug("new cell" .. ix .. "," .. z)
			cells[ix][z] = NewCell(ix, z)
			if DebugEnabled then table.insert(cellList, cells[ix][z]) end
		end
		cells[ix][z][threatResponse][groundAirSubmerged] = cells[ix][z][threatResponse][groundAirSubmerged] + val
	end
end

local function Plot4(cx, cz, x, z, threatResponse, groundAirSubmerged, val)
	HorizontalLine(cx - x, cz + z, cx + x, threatResponse, groundAirSubmerged, val)
	if x ~= 0 and z ~= 0 then
        HorizontalLine(cx - x, cz - z, cx + x, threatResponse, groundAirSubmerged, val)
    end
end 

local function FillCircle(cx, cz, radius, threatResponse, groundAirSubmerged, val)
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
	        Plot4(cx, cz, x, lastZ, threatResponse, groundAirSubmerged, val)
	        if err >= 0 then
	            if x ~= lastZ then Plot4(cx, cz, lastZ, x, threatResponse, groundAirSubmerged, val) end
	            err = err - x
	            x = x - 1
	            err = err - x
	        end
	    end
	end
end

local function CheckHorizontalLine(x, z, tx, threatResponse, groundAirSubmerged)
	-- EchoDebug("horizontal line from " .. x .. " to " .. tx .. " along z " .. z .. " in " .. groundAirSubmerged)
	local value = 0
	local threat = 0
	for ix = x, tx do
		if cells[ix] ~= nil then
			if cells[ix][z] ~= nil then
				local cell = cells[ix][z]
				local value = cell.values[groundAirSubmerged].value -- can't hurt it
				local threat = cell[threatResponse][groundAirSubmerged]
				return value, threat
			end
		end
	end
	return value, threat
end

local function Check4(cx, cz, x, z, threatResponse, groundAirSubmerged)
	local value = 0
	local threat = 0
	local v, t = CheckHorizontalLine(cx - x, cz + z, cx + x, threatResponse, groundAirSubmerged)
	value = value + v
	threat = threat + t
	if x ~= 0 and z ~= 0 then
        local v, t = CheckHorizontalLine(cx - x, cz - z, cx + x, threatResponse, groundAirSubmerged)
        value = value + v
        threat = threat + t
    end
    return value, threat
end 

local function CheckInRadius(cx, cz, radius, threatResponse, groundAirSubmerged)
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
	        local v, t = Check4(cx, cz, x, lastZ, threatResponse, groundAirSubmerged)
	        value = value + v
	        threat = threat + t
	        if err >= 0 then
	            if x ~= lastZ then
	            	local v, t = Check4(cx, cz, lastZ, x, threatResponse, groundAirSubmerged)
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

local function CountEnemyThreat(unitID, unitName, threat)
	if not enemyAlreadyCounted[unitID] then
		currentEnemyThreatCount = currentEnemyThreatCount + threat
		if unitTable[unitName].isBuilding then
			currentEnemyImmobileThreatCount = currentEnemyImmobileThreatCount + threat
		else
			currentEnemyMobileThreatCount = currentEnemyMobileThreatCount + threat
		end
		enemyAlreadyCounted[unitID] = true
	end
end

local function CountDanger(layer, id)
	local danger = dangers[layer]
	if not danger.alreadyCounted[id] then
		danger.count = danger.count + 1
		EchoDebug("spotted " .. layer .. " threat")
		danger.alreadyCounted[id] = true
	end
end

local function DangerCheck(unitName, unitID)
	local un = unitName
	local ut = unitTable[un]
	local id = unitID
	if ut.isBuilding then
		if ut.needsWater then
			CountDanger("watertarget", id)
		else
			CountDanger("landtarget", id)
		end
	end
	if not ut.isBuilding and not commanderList[un] and ut.mtype ~= "air" and ut.mtype ~= "sub" and ut.groundRange > 0 then
		CountDanger("ground", id)
	elseif groundFacList[un] then
		CountDanger("ground", id)
	end
	if ut.mtype == "air" and ut.groundRange > 0 then
		CountDanger("air", id)
	elseif airFacList[un] then
		CountDanger("air", id)
	end
	if (ut.mtype == "sub" or ut.mtype == "shp") and ut.isWeapon and not ut.isBuilding then
		CountDanger("submerged", id)
	elseif subFacList[un] then
		CountDanger("submerged", id)
	end
	if bigPlasmaList[un] then
		CountDanger("plasma", id)
	end
	if nukeList[un] then
		CountDanger("nuke", id)
	end
	if antinukeList[un] then
		CountDanger("antinuke", id)
	end
	if ut.mtype ~= "air" and ut.mtype ~= "sub" and ut.groundRange > 1000 then
		CountDanger("longrange", id)
	end
end

local function NewDangerLayer()
	return { count = 0, alreadyCounted = {}, present = false, obsolesce = 0, threshold = 1, duration = 1800, }
end

local function InitializeDangers()
	dangers = {}
	dangers["watertarget"] = NewDangerLayer()
	dangers["landtarget"] = NewDangerLayer()
	dangers["landtarget"].duration = 2400
	dangers["landtarget"].present = true
	dangers["landtarget"].obsolesce = game:Frame() + 5400
	dangers["ground"] = NewDangerLayer()
	dangers["ground"].duration = 2400 -- keep ground threat alive for one and a half minutes
	-- assume there are ground threats for the first three minutes
	dangers["ground"].present = true
	dangers["ground"].obsolesce = game:Frame() + 5400
	dangers["air"] = NewDangerLayer()
	dangers["submerged"] = NewDangerLayer()
	dangers["plasma"] = NewDangerLayer()
	dangers["nuke"] = NewDangerLayer()
	dangers["antinuke"] = NewDangerLayer()
	dangers["longrange"] = NewDangerLayer()
end

local function UpdateDangers()
	local f = game:Frame()

	for layer, danger in pairs(dangers) do
		if danger.count >= danger.threshold then
			danger.present = true
			danger.obsolesce = f + danger.duration
			danger.count = 0
			danger.alreadyCounted = {}
			EchoDebug(layer .. " danger present")
		elseif danger.present and f >= danger.obsolesce then
			EchoDebug(layer .. " obsolete")
			danger.present = false
		end
	end

	ai.areWaterTargets = dangers.watertarget.present
	ai.areLandTargets = dangers.landtarget.present or not dangers.watertarget.present
	ai.needGroundDefense = dangers.ground.present or (not dangers.air.present and not dangers.submerged.present) -- don't turn off ground defense if there aren't air or submerged dangers
	ai.needAirDefense = dangers.air.present
	ai.needSubmergedDefense = dangers.submerged.present
	ai.needShields = dangers.plasma.present
	ai.needAntinuke = dangers.nuke.present
	ai.canNuke = not dangers.antinuke.present
	ai.needJammers = dangers.longrange.present or dangers.air.present or dangers.nuke.present or dangers.plasma.present
end

local function UpdateEnemies()
	ai.enemyMexSpots = {}
	-- where is/are the party/parties tonight?
	local highestValue = minNukeValue
	local highestValueCell
	for unitID, e in pairs(ai.knownEnemies) do
		local los = e.los
		local ghost = e.ghost
		local name = e.unitName
		local ut = unitTable[name]
		-- only count those we know about and that aren't being built
		if (los ~= 0 or ghost) and not e.beingBuilt then
			local pos
			if ghost then pos = ghost.position else pos = e.position end
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
				if ut.isBuilding then
					cell.value = cell.value + baseBuildingValue
				else
					-- if it moves, assume it's out to get you
					FillCircle(px, pz, baseUnitRange, "threat", "ground", baseUnitThreat)
					FillCircle(px, pz, baseUnitRange, "threat", "air", baseUnitThreat)
					FillCircle(px, pz, baseUnitRange, "threat", "submerged", baseUnitThreat)
				end
			elseif los == 2 then
				local mtype = ut.mtype
				DangerCheck(name, e.unitID)
				local value = Value(name)
				if unitTable[name].extractsMetal ~= 0 then
					table.insert(ai.enemyMexSpots, { position = pos, unit = e })
				end
				if unitTable[name].isBuilding then
					table.insert(cell.buildingIDs, e.unitID)
				end
				local hurtBy = WhatHurtsUnit(name)
				local threatLayers = UnitThreatRangeLayers(name)
				local threatToTurtles = threatLayers.ground.threat + threatLayers.submerged.threat
				local maxRange = max(threatLayers.ground.range, threatLayers.submerged.range)
				for groundAirSubmerged, layer in pairs(threatLayers) do
					if threatToTurtles ~= 0 and hurtBy[groundAirSubmerged] then
						FillCircle(px, pz, maxRange, "response", groundAirSubmerged, threatToTurtles)
					end
					local threat, range = layer.threat, layer.range
					if mtype == "air" and groundAirSubmerged == "ground" or groundAirSubmerged == "submerged" then threat = 0 end -- because air units are pointless to run from
					if threat ~= 0 then
						FillCircle(px, pz, range, "threat", groundAirSubmerged, threat)
						CountEnemyThreat(e.unitID, name, threat)
					elseif mtype ~= "air" then -- air units are too hard to attack
						local health = e.health
						for hurtGAS, hit in pairs(hurtBy) do
							cell.values[groundAirSubmerged][hurtGAS] = cell.values[groundAirSubmerged][hurtGAS] + value
							if cell.targets[groundAirSubmerged][hurtGAS] == nil then
								cell.targets[groundAirSubmerged][hurtGAS] = e
							else
								if value > Value(cell.targets[groundAirSubmerged][hurtGAS].unitName) then
									cell.targets[groundAirSubmerged][hurtGAS] = e
								end
							end
							if health < vulnerableHealth then
								cell.vulnerables[groundAirSubmerged][hurtGAS] = e
							end
							if groundAirSubmerged == "air" and hurtGAS == "ground" and threatLayers.ground.threat > cell.lastDisarmThreat then
								cell.disarmTarget = e
								cell.lastDisarmThreat = threatLayers.ground.threat
							end
						end
						if ut.bigExplosion then
							cell.explosionValue = cell.explosionValue + bomberExplosionValue
							if cell.explosiveTarget == nil then
								cell.explosiveTarget = e
							else
								if value > Value(cell.explosiveTarget.unitName) then
									cell.explosiveTarget = e
								end
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
		enemyBaseCell = highestValueCell
		ai.enemyBasePosition = highestValueCell.pos
	else
		enemyBaseCell = nil
		ai.enemyBasePosition = nil
	end
end

local function UpdateBadPositions()
	local f = game:Frame()
	for i, r in pairs(badPositions) do
		if cells[r.px] then
			cell = cells[r.px][r.pz]
			if cell then
				cell.threat[r.groundAirSubmerged] = cell.threat[r.groundAirSubmerged] + r.threat
			end
		end
		if f > r.frame + r.duration then
			-- remove bad positions after 1 minute
			table.remove(badPositions, i)
		end
	end
end

local function UpdateWrecks()
	-- figure out where all the wrecks are
	for id, w in pairs(ai.knownWrecks) do
		-- will need to check if reclaimer can get to wreck later
		local pos = w.position
		local cell = GetOrCreateCellHere(pos)
		local wname = w.featureName
		local ftable = featureTable[wname]
		if ftable ~= nil then
			cell.metal = cell.metal + ftable.metal
			cell.energy = cell.energy + ftable.energy
			if ftable.unitName ~= nil then
				local rut = unitTable[ftable.unitName]
				if rut.isWeapon or rut.extractsMetal > 0 then
					table.insert(cell.resurrectables, w)
				end
			end
		else
			for findString, metalValue in pairs(baseFeatureMetal) do
				if string.find(wname, findString) then
					cell.metal = cell.metal + metalValue
					break
				end
			end
		end
	end
end

local function UpdateFronts(number)
	local highestCells = {}
	local highestResponses = {}
	for n = 1, number do
		local highestCell = {}
		local highestResponse = { ground = 0, air = 0, submerged = 0 }
		for i = 1, #cellList do
			local cell = cellList[i]
			for groundAirSubmerged, response in pairs(cell.response) do
				local okay = true
				if n > 1 then
					local highCell = highestCells[n-1][groundAirSubmerged]
					if highCell ~= nil then
						if cell == highCell then
							okay = false
						elseif response >= highestResponses[n-1][groundAirSubmerged] then
							okay = false
						else
							local dist = DistanceXZ(highCell.x, highCell.z, cell.x, cell.z)
							if dist < 2 then okay = false end
						end
					end
				end
				if okay and response > highestResponse[groundAirSubmerged] then
					highestResponse[groundAirSubmerged] = response
					highestCell[groundAirSubmerged] = cell
				end
			end
		end
		highestResponses[n] = highestResponse
		highestCells[n] = highestCell
	end
	ai.defendhandler:FindFronts(highestCells)
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

--[[
function TargetHandler:UnitDamaged(unit, attacker,damage)
	-- even if the attacker can't be seen, human players know what weapons look like
	-- but attacker is nil if it's an enemy unit, so this is useless
	if attacker ~= nil then
		local attackerName = attacker:Name()
		local attackerID = attacker:ID()
		DangerCheck(attackerName, attackerID)
	end
end
]]--

function TargetHandler:Init()
	ai.enemyMexSpots = {}
	currentEnemyThreatCount = 0
	currentEnemyImmobileThreatCount = 0
	currentEnemyMobileThreatCount = 0
	enemyAlreadyCounted = {}
	ai.totalEnemyThreat = 10000
	ai.totalEnemyImmobileThreat = 5000
	ai.totalEnemyMobileThreat = 5000
	ai.needGroundDefense = true
	ai.areLandTargets = true
	ai.canNuke = true
	InitializeDangers()
	self.lastEnemyThreatUpdateFrame = 0
	self.feints = {}
	self.raiderCounted = {}
	self.lastUpdateFrame = 0
end

function TargetHandler:Update()
	local f = game:Frame()
	if f > self.lastEnemyThreatUpdateFrame + 1800 or self.lastEnemyThreatUpdateFrame == 0 then
		-- store and reset the threat count
		-- EchoDebug(currentEnemyThreatCount .. " enemy threat last 2000 frames")
		EchoDebug(currentEnemyThreatCount)
		ai.totalEnemyThreat = currentEnemyThreatCount
		ai.totalEnemyImmobileThreat = currentEnemyImmobileThreatCount
		ai.totalEnemyMobileThreat = currentEnemyMobileThreatCount
		currentEnemyThreatCount = 0
		currentEnemyImmobileThreatCount = 0
		currentEnemyMobileThreatCount = 0
		enemyAlreadyCounted = {}
		self.lastEnemyThreatUpdateFrame = f
	end
end

function TargetHandler:AddBadPosition(position, mtype, threat, duration)
	if threat == nil then threat = badCellThreat end
	if duration == nil then duration = 1800 end
	local px, pz = GetCellPosition(position)
	local gas = WhatHurtsUnit(nil, mtype, position)
	local f = game:Frame()
	for groundAirSubmerged, yes in pairs(gas) do
		if yes then
			local newRecord =
			{
				px = px,
				pz = pz,
				groundAirSubmerged = groundAirSubmerged,
				frame = f,
				threat = threat,
				duration = duration,
			}
			table.insert(badPositions, newRecord)
		end
	end
end

function TargetHandler:UpdateMap()
	if ai.lastLOSUpdate > self.lastUpdateFrame then
		self.raiderCounted = {}
		cells = {}
		cellList = {}
		UpdateEnemies()
		UpdateDangers()
		-- UpdateFriendlies()
		UpdateBadPositions()
		UpdateWrecks()
		UpdateFronts(3)
		UpdateDebug()
		self.lastUpdateFrame = game:Frame()
	end
end

local function CellVulnerable(cell, hurtByGAS, weaponsGAS)
	if cell == nil then return end
	for GAS, yes in pairs(hurtByGAS) do
		for i, wGAS in pairs(weaponsGAS) do
			local vulnerable = cell.vulnerables[GAS][wGAS]
			if vulnerable ~= nil then return vulnerable end
		end
	end
end

function TargetHandler:NearbyVulnerable(unit)
	if unit == nil then return end
	self:UpdateMap()
	local position = unit:GetPosition()
	local px, pz = GetCellPosition(position)
	local unitName = unit:Name()
	local gas = WhatHurtsUnit(unitName, nil, position)
	local weapons = UnitWeaponLayerList(unitName)
	-- check this cell
	local vulnerable = nil
	if cells[px] ~= nil then
		if cells[px][pz] ~= nil then
			vulnerable = CellVulnerable(cells[px][pz], gas, weapons)
		end
	end
	-- check adjacent cells
	if vulnerable == nil then
		for ix = px - 1, px + 1 do
			for iz = pz - 1, pz + 1 do
				if cells[ix] ~= nil then
					if cells[ix][iz] ~= nil then
						vulnerable = CellVulnerable(cells[ix][iz], gas, weapons)
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
	local inCell = GetCellHere(rpos)
	local threatReduction = 0
	if inCell ~= nil then
		-- if we're near more raiders, these raiders can target more threatening targets together
		if inCell.raiderHere then threatReduction = threatReduction + inCell.raiderHere end
		if inCell.raiderAdjacent then threatReduction = threatReduction + inCell.raiderAdjacent end
	end
	local rname = representative:Name()
	local maxThreat = baseUnitThreat
	local rthreat, rrange = ThreatRange(rname)
	EchoDebug(rname .. ": " .. rthreat .. " " .. rrange)
	if rthreat > maxThreat then maxThreat = rthreat end
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(rname, cell)
		-- cells with other raiders in or nearby are better places to go for raiders
		if cell.raiderHere then threat = threat - cell.raiderHere end
		if cell.raiderAdjacent then threat = threat - cell.raiderAdjacent end
		threat = threat - threatReduction
		-- EchoDebug(value .. " " .. threat)
		if value > 0 and threat <= maxThreat then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				local mod = value - (threat * 3)
				local dist = Distance(rpos, cell.pos) - mod
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
	local bestValueCell
	local bestValue = -999999
	local bestAnyValueCell
	local bestAnyValue = -999999
	local bestThreatCell
	local bestThreat = 0
	local name = representative:Name()
	local rpos = representative:GetPosition()
	local longrange = unitTable[name].groundRange > 1000
	local mtype = unitTable[name].mtype
	if mtype ~= "sub" and longrange then longrange = true end
	local possibilities = {}
	local highestDist = 0
	local lowestDist = 100000
	for i, cell in pairs(cellList) do
		if cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) or longrange then
				local value, threat = CellValueThreat(name, cell)
				local dist = Distance(rpos, cell.pos)
				if dist > highestDist then highestDist = dist end
				if dist < lowestDist then lowestDist = dist end
				table.insert(possibilities, { cell = cell, value = value, threat = threat, dist = dist })
			end
		end
	end
	local distRange = highestDist - lowestDist
	for i, pb in pairs(possibilities) do
		local fraction = 1.5 - ((pb.dist - lowestDist) / distRange)
		local value = pb.value * fraction
		local threat = pb.threat
		if pb.value > 750 then
			value = 0 - threat
			if value > bestValue then
				bestValueCell = pb.cell
				bestValue = value
			end
		elseif pb.value > 0 then
			value = 0 - threat
			if value > bestAnyValue then
				bestAnyValueCell = pb.cell
				bestAnyValue = value
			end
		elseif threat > bestThreat then
			bestThreatCell = pb.cell
			bestThreat = threat
		end
	end
	local best
	if bestValueCell then
		best = bestValueCell
	elseif enemyBaseCell then
		best = enemyBaseCell
	elseif bestAnyValueCell then
		best = bestAnyValueCell
	elseif bestThreatCell then
		best = bestThreatCell
	elseif self.lastAttackCell then
		best = self.lastAttackCell
	end
	self.lastAttackCell = best
	return best
end

function TargetHandler:GetBestNukeCell()
	self:UpdateMap()
	if enemyBaseCell then return enemyBaseCell end
	local best
	local bestValueThreat = 0
	for i, cell in pairs(cellList) do
		if cell.pos then
			local value, threat = CellValueThreat("ALL", cell)
			if value > minNukeValue then
				local valuethreat = value + threat
				if valuethreat > bestValueThreat then
					best = cell
					bestValueThreat = valuethreat
				end
			end
		end
	end
	return best, bestValueThreat
end

function TargetHandler:GetBestBombardCell(position, range, minValueThreat, ignoreValue, ignoreThreat)
	if ignoreValue and ignoreThreat then
		game:SendToConsole("trying to find a place to bombard but ignoring both value and threat doesn't work")
		return
	end
	self:UpdateMap()
	if enemyBaseCell and not ignoreValue then
		local dist = Distance(position, enemyBaseCell.pos)
		if dist < range then
			local value = enemyBaseCell.values.ground.ground + enemyBaseCell.values.air.ground + enemyBaseCell.values.submerged.ground
			return enemyBaseCell, value + enemyBaseCell.response.ground
		end
	end
	local best
	local bestValueThreat = 0
	if minValueThreat then bestValueThreat = minValueThreat end
	for i, cell in pairs(cellList) do
		if #cell.buildingIDs > 0 then
			local dist = Distance(position, cell.pos)
			if dist < range then
				local value = cell.values.ground.ground + cell.values.air.ground + cell.values.submerged.ground
				local valuethreat = 0
				if not ignoreValue then valuethreat = valuethreat + value end
				if not ignoreThreat then valuethreat = valuethreat + cell.response.ground end
				if valuethreat > bestValueThreat then
					best = cell
					bestValueThreat = valuethreat
				end
			end
		end
	end
	if best then
		local bestBuildingID, bestBuildingVT
		for i, buildingID in pairs(best.buildingIDs) do
			local building = game:GetUnitByID(buildingID)
			if building then
				local uname = building:Name()
				local value = Value(uname)
				local threat = ThreatRange(uname, "ground") + ThreatRange(uname, "air")
				local valueThreat = value + threat
				if not bestBuildingVT or valueThreat > bestBuildingVT then
					bestBuildingVT = valueThreat
					bestBuildingID = buildingID
				end
			end
		end
	end
	return best, bestValueThreat, bestBuildingID
end

function TargetHandler:GetBestBomberTarget(torpedo)
	self:UpdateMap()
	local best
	local bestValue = 0
	for i, cell in pairs(cellList) do
		local value = cell.explosionValue
		if torpedo then
			value = value + cell.values.air.submerged
		else
			value = value + cell.values.air.ground
		end
		if value > 0 then
			value = value - cell.threat.air
			if value > bestValue then
				best = cell
				bestValue = value
			end
		end
	end
	if best then
		local bestTarget
		bestValue = 0
		local target = best.explosiveTarget
		if target == nil then
			if torpedo then
				target = best.targets.air.submerged
			else
				target = best.targets.air.ground
			end
		end
		return target
	end
end

function TargetHandler:GetBestReclaimCell(representative, lookForEnergy)
	if not representative then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local rname = representative:Name()
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(rname, cell)
		if threat == 0 and cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				local mod
				if lookForEnergy then
					mod = cell.energy
				else
					mod = cell.metal
				end
				local vulnerable = CellVulnerable(cell, gas, UnitWeaponLayerList(rname))
				if vulnerable then mod = mod + vulnerableReclaimDistMod end
				if mod > 0 then
					local dist = Distance(rpos, cell.pos) - mod
					if dist < bestDist then
						best = cell
						bestDist = dist
					end
				end
			end
		end
	end
	return best
end

function TargetHandler:WreckToResurrect(representative)
	if not representative then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local rname = representative:Name()
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		if #cell.resurrectables ~= 0 then
			local value, threat, gas = CellValueThreat(rname, cell)
			if threat == 0 and cell.pos then
				if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
					local dist = Distance(rpos, cell.pos)
					if dist < bestDist then
						best = cell
						bestDist = dist
					end
				end
			end
		end
	end
	if best then
		EchoDebug("got wreck to resurrect")
		local bestWreck
		local bestMetalCost = 0
		for i, w in pairs(best.resurrectables) do
			if w ~= nil then
				local wname = w.featureName
				if wname ~= nil then
					local ft = featureTable[wname]
					if ft ~= nil then
						local ut = unitTable[ft.unitName]
						if ut ~= nil then
							local metalCost = ut.metalCost
							if metalCost > bestMetalCost then
								bestWreck = w
								bestMetalCost = metalCost
							end
						end
					end
				end
			end
		end
		return bestWreck, best
	else
		return nil, self:NearestVulnerableCell(representative)
	end
end

function TargetHandler:NearestVulnerableCell(representative)
	if representative == nil then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local rname = representative:Name()
	local best
	local bestDist = 99999
	local weapons = UnitWeaponLayerList(rname)
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(rname, cell)
		if threat == 0 and cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				if CellVulnerable(cell, gas, weapons) ~= nil then
					local dist = Distance(rpos, cell.pos)
					if dist < bestDist then
						best = cell
						bestDist = dist
					end
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
	local groundValue, groundThreat = CheckInRadius(px, pz, radius, "threat", "ground")
	if groundValue + groundThreat > Value(unitName) * 1.5 then
		return true
	else
		return false
	end
end

function TargetHandler:IsSafePosition(position, unit, threshold)
	self:UpdateMap()
	if unit == nil then game:SendToConsole("nil unit") end
	local uname = unit:Name()
	if uname == nil then game:SendToConsole("nil unit name") end
	local cell = GetCellHere(position)
	if cell == nil then return 0, 0 end
	local value, threat = CellValueThreat(uname, cell)
	if threshold then
		return threat < unitTable[uname].metalCost * threshold, cell.response
	else
		return threat == 0, cell.response
	end
end

-- for on-the-fly enemy evasion
function TargetHandler:BestAdjacentPosition(unit, targetPosition)
	local position = unit:GetPosition()
	local px, pz = GetCellPosition(position)
	local tx, tz = GetCellPosition(targetPosition)
	if px >= tx - 1 and px <= tx + 1 and pz >= tz - 1 and pz <= tz + 1 then
		-- if we're already in the target cell or adjacent to it, keep moving
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
	local doubleUnitRange = urange * 2
	for x = px - 1, px + 1 do
		for z = pz - 1, pz + 1 do
			if x == px and z == pz then
				-- don't move to the cell you're already in
			else
				local dist = dist2d(tx, tz, x, z) * cellElmos
				if cells[x] ~= nil then
					if cells[x][z] ~= nil then
						local value, threat = CellValueThreat(uname, cells[x][z])
						if raiderList[uname] then
							-- cells with other raiders in or nearby are better places to go for raiders
							if cells[x][z].raiderHere then threat = threat - cells[x][z].raiderHere end
							if cells[x][z].raiderAdjacent then threat = threat - cells[x][z].raiderAdjacent end
						end
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
	end
	if best and notsafe then
		local mtype = unitTable[uname].mtype
		self:AddBadPosition(targetPosition, mtype, 16, 1200) -- every thing to avoid on the way to the target increases its threat a tiny bit
		table.insert(self.feints, {x = best.x, z = best.z, px = px, pz = pz, tx = tx, tz = tz, frame = f})
		return best.pos
	end
end

function TargetHandler:RaiderHere(raidbehaviour)
	if raidbehaviour == nil then return end
	if raidbehaviour.unit == nil then return end
	if self.raiderCounted[raidbehaviour.id] then return end
	local unit = raidbehaviour.unit:Internal()
	if unit == nil then return end
	local uthreat, urange = ThreatRange(unit:Name())
	local position = unit:GetPosition()
	local px, pz = GetCellPosition(position)
	local inCell
	if cells[px] then
		inCell = cells[px][pz]
	end
	if inCell ~= nil then
		if inCell.raiderHere == nil then inCell.raiderHere = 0 end
		inCell.raiderHere = inCell.raiderHere + (uthreat * 0.67)
	end
	local adjacentThreatReduction = uthreat * 0.33
	for x = px - 1, px + 1 do
		if cells[x] ~= nil then
			for z = pz - 1, pz + 1 do
				if x == px and z == pz then
					-- ignore center cell
				else
					local cell = cells[x][z]
					if cell ~= nil then
						if cell.raiderAdjacent == nil then cell.raiderAdjacent = 0 end
						cell.raiderAdjacent = cell.raiderAdjacent + adjacentThreatReduction
					end
				end
			end
		end
	end
	self.raiderCounted[raidbehaviour.id] = true -- reset with UpdateMap()
end
