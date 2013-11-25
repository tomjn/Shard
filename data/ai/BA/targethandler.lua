
require "common"

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
local vulnerableReclaimDistMod = 100
local badCellThreat = 300

local factoryValue = 1000
local conValue = 300
local techValue = 100
local minNukeValue = factoryValue + techValue + 500

local feintRepeatMod = 25

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

local lastUpdateFrame = 0

local function NewCell(px, pz)
	local newcell = {value = 0, groundValue = 0, airValue = 0, submergedValue = 0, bomberValue = 0, groundThreat = 0, airThreat = 0, submergedThreat = 0, bomberTargets = {}, resurrectables = {}, metal = 0, energy = 0, friendlyValue = 0, friendlyBuildings = 0, friendlyLandCombats = 0, friendlyAirCombats = 0, friendlyWaterCombats = 0, x = px, z = pz}
	return newcell
end

local function ThreatRange(unitName, groundAirSubmerged)
	if antinukeList[unitName] or nukeList[unitName] or bigPlasmaList[unitName] or shieldList[unitName] then
		return 0, 0
	end
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
	if groundAirSubmerged == "ground" and utable.mtype ~= "air" then -- air units ignored because they move too fast for their position to matter for ground threat calculations
		range = utable.groundRange
	elseif groundAirSubmerged == "air" then
		range = utable.airRange
		if range == 0 then
			-- ground weapons can hurt air units sometimes
			if utable.groundRange > 0 then
				return math.ceil(utable.metalCost * 0.1), utable.groundRange
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
		if unitTable[e:Name()].isBuilding then
			currentEnemyImmobileThreatCount = currentEnemyImmobileThreatCount + threat
		else
			currentEnemyMobileThreatCount = currentEnemyMobileThreatCount + threat
		end
		enemyAlreadyCounted[e] = true
	end
end

local function CountDanger(layer, id)
	local danger = dangers[layer]
	if not danger.alreadyCounted[id] then
		danger.count = danger.count + 1
		danger.alreadyCounted[id] = true
		EchoDebug("spotted " .. layer .. " threat")
	end
end

local function DangerCheck(unitName, unitID)
	local un = unitName
	local ut = unitTable[un]
	local id = unitID
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
		elseif danger.present and f >= danger.obsolesce then
			EchoDebug(layer .. " obsolete")
			danger.present = false
		end
	end

	ai.needGroundDefense = dangers.ground.present or (not dangers.air.present and not dangers.submerged.present) -- don't turn off ground defense if there aren't air or submerged dangers
	ai.needAirDefense = dangers.air.present
	ai.needSubmergedDefense = dangers.submerged.present
	ai.needShields = dangers.plasma.present
	ai.needAntinuke = dangers.nuke.present
	ai.canNuke = not dangers.antinuke.present
	ai.needJammers = dangers.longrange.present or dangers.air.present or dangers.nuke.present or dangers.plasma.present
end

local function UpdateEnemies()
	local enemies = game:GetEnemies()
	if enemies == nil then return end
	if #enemies == 0 then return end

	-- figure out where all the enemies are!
	local highestValue = minNukeValue
	local highestValueCell
	for i, e in pairs(enemies) do
		local los = ai.loshandler:IsKnownEnemy(e)
		local ghost = ai.loshandler:GhostPosition(e)
		local name = e:Name()
		-- only count those we know about and that aren't being built
		if (los ~= 0 or ghost) and not e:IsBeingBuilt() then
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
				DangerCheck(name, e:ID())
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
		enemyBaseCell = highestValueCell
		ai.enemyBasePosition = highestValueCell.pos
	else
		enemyBaseCell = nil
		ai.enemyBasePosition = nil
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
			if cell.pos == nil then
				cell.pos = pos
			end
			local wname = w:Name()
			local ftable = featureTable[wname]
			if ftable ~= nil then
				cell.metal = cell.metal + ftable.metal
				cell.energy = cell.energy + ftable.energy
				if ftable.unitName ~= nil then
					if unitTable[ftable.unitName].isWeapon then
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

function TargetHandler:UnitDamaged(unit, attacker)
	-- even if the attacker can't be seen, human players know what weapons look like
	if attacker ~= nil then
		local attackerName = attacker:Name()
		local attackerID = attacker:ID()
		DangerCheck(attackerName, attackerID)
	end
end

function TargetHandler:Init()
	currentEnemyThreatCount = 0
	currentEnemyImmobileThreatCount = 0
	currentEnemyMobileThreatCount = 0
	enemyAlreadyCounted = {}
	ai.totalEnemyThreat = 10000
	ai.totalEnemyImmobileThreat = 5000
	ai.totalEnemyMobileThreat = 5000
	ai.needGroundDefense = true
	ai.canNuke = true
	InitializeDangers()
	self.lastEnemyThreatUpdateFrame = 0
	self.feints = {}
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
		UpdateDangers()
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
	if enemyBaseCell then return enemyBaseCell end
	local bestValueCell
	local bestValue = 0
	local bestThreatCell
	local bestThreat = 0
	local name = representative:Name()
	local longrange = unitTable[name].groundRange > 650
	local mtype = unitTable[name].mtype
	if mtype ~= "sub" and longrange then longrange = true end
	for i, cell in pairs(cellList) do
		if cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) or longrange then
				local value, threat = CellValueThreat(representative, cell)
				if value > 0 then
					if value > bestValue then
						bestValueCell = cell
						bestValue = value
					end
				elseif threat > 0 then
					if threat > bestThreat then
						bestThreatCell = cell
						bestThreat = threat
					end
				end
			end
		end
	end
	if bestValueCell then
		return bestValueCell
	else
		return bestThreatCell
	end
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
		if dist < range then return enemyBaseCell end
	end
	local best
	local bestValueThreat = 0
	if minValueThreat then bestValueThreat = minValueThreat end
	for i, cell in pairs(cellList) do
		local dist = Distance(position, cell.pos)
		if dist < range then
			local value, threat = CellValueThreat("ALL", cell)
			local valuethreat = 0
			if not ignoreValue then valuethreat = valuethreat + value end
			if not ignoreThreat then valuethreat = valuethreat + threat end
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

function TargetHandler:GetBestReclaimCell(representative, lookForEnergy)
	if not representative then return end
	self:UpdateMap()
	local rpos = representative:GetPosition()
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		local value, threat, gas = CellValueThreat(representative, cell)
		if threat == 0 and cell.pos then
			if ai.maphandler:UnitCanGoHere(representative, cell.pos) then
				local mod
				if lookForEnergy then
					mod = cell.energy
				else
					mod = cell.metal
				end
				if mod > 0 then
					local dist = Distance(rpos, cell.pos) - mod
					local vulnerable = CellVulnerable(cell, gas)
					if vulnerable then dist = dist - vulnerableReclaimDistMod end
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
	local best
	local bestDist = 99999
	for i, cell in pairs(cellList) do
		if #cell.resurrectables ~= 0 then
			local value, threat, gas = CellValueThreat(representative, cell)
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
		local bestWreck
		local bestMetalCost = 0
		for i, w in pairs(best.resurrectables) do
			if w ~= nil then
				local wname = w:Name()
				if wname ~= nil then
					local metalCost = unitTable[featureTable[wname].unitName].metalCost
					if metalCost > bestMetalCost then
						bestWreck = w
						bestMetalCost = metalCost
					end
				end
			end
		end
		return bestWreck
	end
end

function TargetHandler:IsBombardPosition(position, unitName)
	self:UpdateMap()
	local px, pz = GetCellPosition(position)
	local radius = unitTable[unitName].groundRange
	local groundValue, groundThreat = CheckInRadius(px, pz, radius, "ground")
	if groundValue + groundThreat > Value(unitName) * 2 then
		return true
	else
		return false
	end
end

function TargetHandler:IsSafePosition(position, unit, threshold)
	self:UpdateMap()
	if unit == nil then game:SendToConsole("nil unit") end
	if unit:Name() == nil then game:SendToConsole("nil unit name") end
	local cell = GetCellHere(position)
	local value, threat = CellValueThreat(unit, cell)
	if threshold then
		return threat < unitTable[unit:Name()].metalCost * threshold
	else
		return threat == 0
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
	end
	if best and notsafe then
		table.insert(self.feints, {x = best.x, z = best.z, px = px, pz = pz, tx = tx, tz = tz, frame = f})
		return best.pos
	end
end