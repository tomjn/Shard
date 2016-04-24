--[[
 Task Queues!
]]--

require "common"
shard_include('taskBot')
shard_include('taskVeh')
shard_include('taskShp')
shard_include('taskAir')
shard_include('taskHov')
shard_include('taskEco')
shard_include('taskBuild')
shard_include('taskExp')

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("Taskqueues: " .. inStr)
	end
end

local random = math.random
math.randomseed( os.time() + game:GetTeamID() )
random(); random(); random()

needAA = false
needShields = false
needAntinuke = false
needtorpedo = false
needGroundDefense = true

-- do we need siege equipment such as artillery and merl?
needSiege = false

heavyPlasmaLimit = 3 -- changes with CheckForMapControl
AAUnitPerTypeLimit = 3 -- changes with CheckForMapControl
nukeLimit = 1 -- changes with CheckForMapControl
tacticalNukeLimit = 1 -- changes with CheckForMapControl

lastCheckFrame = 0
lastSiegeCheckFrame = 0

-- build ranges to check for things
AreaCheckRange = 1500

tidalPower = 0

averageWind = 0
needWind = false
windRatio = 1

needAmphibiousCons = false

minDefenseNetworkSize = 100000

function MapHasWater()
	return (ai.waterMap or ai.hasUWSpots) or false
end

function CheckMySide(self)
	-- fix: moved here so map object is present when it's accessed
	ConUnitPerTypeLimit = math.max(map:SpotCount() / 6, 4)
	ConUnitAdvPerTypeLimit = math.max(map:SpotCount() / 8, 2)


	EchoDebug("per-type construction unit limit: " .. ConUnitPerTypeLimit)
	minDefenseNetworkSize = ai.mobilityGridArea / 4 
	-- set the averageWind
	if averageWind == 0 then
		averageWind = map:AverageWind()
		if averageWind > 11 then
			needWind = true
		else
			needWind = false
		end
		local minWind = map:MinimumWindSpeed()
		if minWind < 8 then
			windRatio = minWind / 8
		else
			windRatio = 1
		end
		EchoDebug("wind/solar ratio: " .. windRatio)
	end
	-- set the tidal strength
	if MapHasWater() then
		if tidalPower == 0 then tidalPower = map:TidalStrength() end
	else
		tidalPower = 0
	end
	if ai.hasUWSpots and ai.mobRating["sub"] > ai.mobRating["bot"] * 0.75 then
		needAmphibiousCons = true
	end
	if self.unit ~= nil then
		local tmpName = self.unit:Internal():Name()
		if tmpName == "corcom" then
			ai.mySide = CORESideName
			return DummyUnitName
		end
		if tmpName == "armcom" then
			ai.mySide = ARMSideName
			return DummyUnitName
		end
		game:SendToConsole("Unexpected start unit: "..tmpName..", cannot determine it's race. Assuming CORE")
		ai.mySide = CORESideName
	else
		game:SendToConsole("Unexpected start unit: nil, cannot determine it's race. Assuming CORE")
		ai.mySide = CORESideName
	end
	return DummyUnitName
end

-- this is initialized in maphandler
function MapHasUnderwaterMetal()
	return ai.hasUWSpots or false
end

-- check if siege units are needed
-- check if advanced and experimental factories are needed
-- check if nukes are needed
-- check if reclaiming is needed
function CheckForMapControl()
	local f = game:Frame()
	if (lastSiegeCheckFrame + 240) < f then
		ai.haveAdvFactory = false
		if ai.factoriesAtLevel[3] ~= nil then
			ai.haveAdvFactory = #ai.factoriesAtLevel[3] ~= 0
		end
		ai.haveExpFactory = false
		if ai.factoriesAtLevel[5] ~= nil then
			ai.haveExpFactory = #ai.factoriesAtLevel[5] ~= 0
		end
		
		lastSiegeCheckFrame = f
		ai.needToReclaim = ai.Metal.full < 0.5 and ai.wreckCount > 0
		AAUnitPerTypeLimit = math.ceil(ai.turtlehandler:GetTotalPriority() / 4)
		heavyPlasmaLimit = math.ceil(ai.combatCount / 10)
		nukeLimit = math.ceil(ai.combatCount / 50)
		tacticalNukeLimit = math.ceil(ai.combatCount / 40)

		local attackCounter = ai.attackhandler:GetCounter()
		local couldAttack = ai.couldAttack >= 1 or ai.couldBomb >= 1
		local bombingTooExpensive = ai.bomberhandler:GetCounter() == maxBomberCounter
		local attackTooExpensive = attackCounter == maxAttackCounter
		local controlMetalSpots = ai.mexCount > #ai.mobNetworkMetals["air"][1] * 0.4
		local needUpgrade = couldAttack or bombingTooExpensive or attackTooExpensive
		local lotsOfMetal = ai.Metal.income > 25 or controlMetalSpots

		EchoDebug(ai.totalEnemyThreat .. " " .. ai.totalEnemyImmobileThreat .. " " .. ai.totalEnemyMobileThreat)
		-- build siege units if the enemy is turtling, if a lot of our attackers are getting destroyed, or if we control over 40% of the metal spots
		needSiege = (ai.totalEnemyImmobileThreat > ai.totalEnemyMobileThreat * 3.5 and ai.totalEnemyImmobileThreat > 50000) or attackCounter >= siegeAttackCounter or controlMetalSpots
		ai.needAdvanced = (ai.Metal.income > 10 or controlMetalSpots) and ai.factories > 0 and (needUpgrade or lotsOfMetal)
		ai.needExperimental = false
		ai.needNukes = false
		if ai.Metal.income > 50 and ai.haveAdvFactory and needUpgrade and ai.enemyBasePosition then
			if not ai.haveExpFactory then
				for i, factory in pairs(ai.factoriesAtLevel[ai.maxFactoryLevel]) do
					if ai.maphandler:MobilityNetworkHere("bot", factory.position) == ai.maphandler:MobilityNetworkHere("bot", ai.enemyBasePosition) then
						ai.needExperimental = true
						break
					end
				end
			end
			ai.needNukes = true
		end
		EchoDebug("need experimental? " .. tostring(ai.needExperimental) .. ", need nukes? " .. tostring(ai.needNukes) .. ", have advanced? " .. tostring(ai.haveAdvFactory) .. ", need upgrade? " .. tostring(needUpgrade) .. ", have enemy base position? " .. tostring(ai.enemyBasePosition))
		EchoDebug("metal income: " .. ai.Metal.income .. "  combat units: " .. ai.combatCount)
		EchoDebug("have advanced? " .. tostring(ai.haveAdvFactory) .. " have experimental? " .. tostring(ai.haveExpFactory))
		EchoDebug("need advanced? " .. tostring(ai.needAdvanced) .. "  need experimental? " .. tostring(ai.needExperimental))
		EchoDebug("need advanced? " .. tostring(ai.needAdvanced) .. ", need upgrade? " .. tostring(needUpgrade) .. ", have attacked enough? " .. tostring(couldAttack) .. " (" .. ai.couldAttack .. "), have " .. ai.factories .. " factories, " .. math.floor(ai.Metal.income) .. " metal income")
	end
end

function IsSiegeEquipmentNeeded()
	CheckForMapControl()
	return needSiege
end

function IsAANeeded()
	return ai.needAirDefense
end

function IsShieldNeeded()
	return ai.needShields
end

function IsTorpedoNeeded()
	return ai.needSubmergedDefense
end

function IsJammerNeeded()
	return ai.needJammers
end

function IsAntinukeNeeded()
	return ai.needAntinuke
end

function IsNukeNeeded()
	local nuke = ai.needNukes and ai.canNuke
	return nuke
end

function IsLandAttackNeeded()
	return ai.areLandTargets or ai.needGroundDefense
end

function IsWaterAttackNeeded()
	return ai.areWaterTargets or ai.needSubmergedDefense
end

function have(name,number)
	--print(tostring(ai.nameCountFinished[name]))
	if ai.nameCountFinished[name]~=nil then
		if ai.nameCountFinished[name]>=number then
			--print(tostring('ai have' .. name))
			return true
		end
	else
		--print(tostring('ai dont have sufficient ' .. name))
		return false
	end
end

function CountOwnUnits(tmpUnitName)
	if tmpUnitName == DummyUnitName then return 0 end -- don't count no-units
	if ai.nameCount[tmpUnitName] == nil then return 0 end
	return ai.nameCount[tmpUnitName]
end

function BuildWithLimitedNumber(tmpUnitName, minNumber)
	if tmpUnitName == DummyUnitName then return DummyUnitName end
	if minNumber == 0 then return DummyUnitName end
	if ai.nameCount[tmpUnitName] == nil then
		return tmpUnitName
	else
		if ai.nameCount[tmpUnitName] == 0 or ai.nameCount[tmpUnitName] < minNumber then
			return tmpUnitName
		else
			return DummyUnitName
		end
	end
end

function BuildConNumber(tmpUnitName, MaxNumber)
	if tmpUnitName == DummyUnitName then return DummyUnitName end
	if MaxNumber == 0 then return DummyUnitName end
	local target=ai.nameCountFinished[tmpUnitName]
	if target == nil then
		return tmpUnitName
	else
		if target < MaxNumber then
			return tmpUnitName
		else
			return DummyUnitName
		end
	end
end

function GroundDefenseIfNeeded(unitName, builder)
	if not ai.needGroundDefense then
		return DummyUnitName
	else
		return unitName
	end
end


function CheckMySideIfNeeded()
	if ai.mySide == nil then
		EchoDebug("commander: checkmyside")
		return CheckMySide
	else
		return DummyUnitName
	end
end

function FactoryOrNano(self)
	CheckForMapControl()
	if ai.factories == 0 then return BuildAppropriateFactory() end
	EchoDebug("factories: " .. ai.factories .. "  combat units: " .. ai.combatCount)
	local unitName = DummyUnitName
	local attackCounter = ai.attackhandler:GetCounter()
	local couldAttack = ai.couldAttack >= 2 or ai.couldBomb >= 2
	if (ai.combatCount > attackCounter * 0.5 and couldAttack) or ai.needAdvanced then
		unitName = BuildAppropriateFactory()
	end
	if unitName == DummyUnitName and ai.combatCount > attackCounter * 0.2 then
		unitName = NanoTurret()
	end
	return unitName
end

function BuildWindSolarIfNeeded()
	-- check if we need power
	if ai.Energy.extra < 0 then
		retVal = WindSolar
		EchoDebug("BuildWindSolarIfNeeded: income "..res.income..", usage "..res.usage..", building more energy")
	else
		retVal = DummyUnitName
	end

	return retVal
end

function WindSolarTidal(self)
	LandOrWater(self, WindSolar(), TidalIfTidal())
end


function LandOrWater(self, landName, waterName)
	local builder = self.unit:Internal()
	local bpos = builder:GetPosition()
	local waterNet = ai.maphandler:MobilityNetworkSizeHere("shp", bpos)
	if waterNet ~= nil then
		return waterName
	else
		return landName
	end
end

function BuildAAIfNeeded(unitName)
	if IsAANeeded() then
		if not unitTable[unitName].isBuilding then
			return BuildWithLimitedNumber(unitName, AAUnitPerTypeLimit)
		else
			return unitName
		end
	else
		return DummyUnitName
	end
end

function BuildTorpedoIfNeeded(unitName)
	if IsTorpedoNeeded() then
		return unitName
	else
		return DummyUnitName
	end
end

function BuildSiegeIfNeeded(unitName)
	if unitName == DummyUnitName then return DummyUnitName end
	if IsSiegeEquipmentNeeded() then
		if ai.siegeCount < (ai.battleCount + ai.breakthroughCount) * 0.35 then
			return unitName
		end
	end
	return DummyUnitName
end

function BuildBreakthroughIfNeeded(unitName)
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	if IsSiegeEquipmentNeeded() then return unitName end
	local mtype = unitTable[unitName].mtype
	if mtype == "air" then
		local bomberCounter = ai.bomberhandler:GetCounter()
		if bomberCounter >= breakthroughBomberCounter and bomberCounter < maxBomberCounter then
			return unitName
		else
			return DummyUnitName
		end
	else
		if ai.battleCount <= minBattleCount then return DummyUnitName end
		local attackCounter = ai.attackhandler:GetCounter(mtype)
		if attackCounter == maxAttackCounter then
			return unitName
		elseif attackCounter >= breakthroughAttackCounter then
			return unitName
		else
			return DummyUnitName
		end
	end
end

function BuildRaiderIfNeeded(unitName)
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	local mtype = unitTable[unitName].mtype
	if ai.factoriesAtLevel[3] ~= nil and ai.factoriesAtLevel[3] ~= {} then
		-- if we have a level 2 factory, don't build raiders until we have some battle units
		local attackCounter = ai.attackhandler:GetCounter(mtype)
		if ai.battleCount + ai.breakthroughCount < attackCounter / 2 then
			return DummyUnitName
		end
	end
	local counter = ai.raidhandler:GetCounter(mtype)
	if counter == minRaidCounter then return DummyUnitName end
	if ai.raiderCount[mtype] == nil then
		-- fine
	elseif ai.raiderCount[mtype] >= counter then
		unitName = DummyUnitName
	end
	return unitName
end

function BuildBattleIfNeeded(unitName)
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	local mtype = unitTable[unitName].mtype
	local attackCounter = ai.attackhandler:GetCounter(mtype)
	EchoDebug(mtype .. " " .. attackCounter .. " " .. maxAttackCounter)
	if attackCounter == maxAttackCounter and ai.battleCount > minBattleCount then return DummyUnitName end
	if mtype == "veh" and ai.mySide == CORESideName and (ai.factoriesAtLevel[1] == nil or ai.factoriesAtLevel[1] == {}) then
		-- core only has a lvl1 vehicle raider, so this prevents getting stuck
		return unitName
	end
	if ai.factoriesAtLevel[3] ~= nil and ai.factoriesAtLevel[3] ~= {} then
		-- if we have a level 2 factory, don't wait to build raiders first
		return unitName
	end
	local raidCounter = ai.raidhandler:GetCounter(mtype)
	EchoDebug(mtype .. " " .. raidCounter .. " " .. maxRaidCounter)
	if raidCounter == minRaidCounter then return unitName end
	EchoDebug(ai.raiderCount[mtype])
	if ai.raiderCount[mtype] == nil then
		return unitName
	elseif ai.raiderCount[mtype] < raidCounter / 2 then
		return DummyUnitName
	else
		return unitName
	end
end


function corDebug(self)
	game:SendToConsole("d")
	return "corwin"
end

function BuildBomberIfNeeded(unitName)
	if not IsLandAttackNeeded() then return DummyUnitName end
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	if ai.bomberhandler:GetCounter() == maxBomberCounter then
		return DummyUnitName
	else
		return unitName
	end
end

function BuildTorpedoBomberIfNeeded(unitName)
	if not IsWaterAttackNeeded() then return DummyUnitName end
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	if ai.bomberhandler:GetCounter() == maxBomberCounter then
		return DummyUnitName
	else
		return unitName
	end
end

--complex
local function lv1GroundEco(self)
        local unitName=DummyUnitName
	if ef>0.3  and mf >0.3 then
		unitName=NanoTurret()
		--print(tostring('2'))
	elseif 	ef>0.9 and ei>100  then
		unitName=buildEstore1(self)
		--print(tostring('3'))
	elseif mf>0.75 and mi>10  then
		unitName=buildMstore1(self)
		--print(tostring('5'))
	elseif ef>0.8 and ei>50  then
		unitName=buildMconv1(self)
	else
		unitName=Energy1(self)
	end
	EchoDebug('e1 '..unitName)
	return unitName
end

local function Economy0(self)
        local unitName=DummyUnitName
	
	if 	ef>0.9 and ei>100  and mf>0.5 then
		unitName=buildEstore1(self)
		--print(tostring('c3'))
	elseif mf>0.7 and mi>10  then
		unitName=buildMstore1(self)
		--print(tostring('c5'))
	elseif ef>0.8 and ei>50 then
		unitName=buildMconv1(self)
		--print(tostring('c4'))
	elseif ef>0.3 and (mi<1 or mf<0.6) then
		unitName=BuildMex0()
		--print(tostring('c1'))
	elseif (ef<0.5 or ei<eu)   then
		unitName=WindSolar(self)
	elseif mf<0.3 or mi< 3 then
		unitName=BuildMex0(self)
		--print(tostring('c2'))


	end
	EchoDebug('commander '..unitName)
	return unitName
end

local function Economy1(self)
        local unitName=DummyUnitName
	if ef>0.3  and mf >0.3 then
		unitName=NanoTurret()
	elseif (ef<0.3 or ei<eu) and mf>0.1 then
		unitName=Energy1(self)
		--print(tostring('2'))
	elseif 	ef>0.9 and ei>100 and mi>mu  then
		unitName=buildEstore1(self)
		--print(tostring('3'))
	elseif mf>0.7 and mi>10  then
		unitName=buildMstore1(self)
		--print(tostring('5'))
	elseif ef>0.8 and ei>50  then
		unitName=buildMconv1(self)
	elseif mf<0.3 or mi< 3 then
		unitName=BuildMex1()
	end
	EchoDebug('e1 '..unitName)
	return unitName
end

local function EconomyBattleEngineer(self)
        local unitName=DummyUnitName
	if ef>0.2 and mi>mu and mf >0.2 then
		unitName=NanoTurret()
	elseif (ef<0.1) and mf>0.3 then
		unitName=Solar(self)
	elseif mf<0.1 then 
		unitName=BuildMex0()
	end
	--print(tostring('EBE '..unitName))
	return unitName
end

local function EconomyNavalEngineer(self)
        local unitName=DummyUnitName
	if ef<0.2 and mi>mu and mf >0.2 then
		unitName=TidalIfTidal(self)
	elseif mf<0.2 and ei>eu and ef>0.2 then
		unitName=BuildUWMex(self)
	end
	--print(tostring('ENE '..unitName))
	return unitName
end


local function Economy3(self)
	local unitName=DummyUnitName
	if 	ef>0.9 and ei>1000 and mi>mu then
		unitName=buildEstore2(self)
		--print(tostring('a3'))
	elseif mf>0.8 and mi>30 and ef>0.1  then
		unitName=buildMstore2(self)
		--print(tostring('a5'))
	elseif ef>0.8  then
		unitName=buildMconv2(self)
		--print(tostring('a4'))
	elseif mf<0.2 and ef>0.1 then
		unitName=BuildMohoMex()
		--print(tostring('a1'))
	elseif (ef<0.3 or ei<eu) then
		unitName=BuildFusion3(self)
	end
	--print(tostring('E3 '..unitName))
	return unitName
end

local function lv3GroundEco(self)
	local unitName=DummyUnitName

	if ef>0.8  then
		unitName=buildMconv2(self)
		--print(tostring('a4'))
	else 
		unitName=BuildFusion3(self)
	end
	--print(tostring('E3 '..unitName))
	return unitName
end

local function Economy2(self)
	local unitName=DummyUnitName
	if 	ef>0.9 and ei>1000 and mi>mu then
		unitName=buildEstore2(self)
		--print(tostring('a3'))
	elseif mf>0.7 and mi>30  then
		unitName=buildMstore2(self)
		--print(tostring('a5'))
	elseif ef>0.8  then
		unitName=buildMconv2(self)
		--print(tostring('a4'))
	elseif ef>0.2 then
		unitName=BuildMohoMex()
		--print(tostring('a1'))
	elseif (ef<0.3 or ei<eu) then
		unitName=BuildFusion(self)
	end
	--print(tostring('E2 '..unitName))
	return unitName
end

	
local function EconomyUnderWater(self)
	local unitName=DummyUnitName
	if 	ef>0.9 and ei>100  and mi>mu then
		unitName=buildWEstore1(self)
		--print(tostring('cw3'))
	elseif mf>0.7 and mi>10  then
		unitName=buildWMstore1(self)
		--print(tostring('cw5'))
	elseif ef>0.8 and ei>50 then
		unitName=buildWMconv1(self)
		--print(tostring('cw4'))
	elseif ef>0.1 and (mi<1 or mf<0.6) then
		unitName=BuildUWMex()
		--print(tostring('cw1'))
	elseif (ef<0.3 or ei<eu) and mi>3 and mf>0.1 then
		unitName=TidalIfTidal(self)
		--print(tostring('cw2'))
	else
		unitName=BuildUWMex()
		--unitName=NanoTurret()
		--print(tostring('cw6'))
	end
	--print(tostring('cw '..unitName))
	return unitName
end

local function EconomyUnderWater2(self)
	local unitName=DummyUnitName
	if 	ef>0.9 and ei>1000 and mi>mu then
		unitName=buildEstore2(self)
		--print(tostring('aw3'))
	elseif mf>0.7 and mi>30  then
		unitName=buildMstore2(self)
		--print(tostring('aw5'))
	elseif ef>0.8  then
		unitName=buildMconv2UW(self)
		--print(tostring('aw4'))
	elseif ef>0.2 then
		unitName=BuildUWMohoMex()
		--print(tostring('aw1'))
	elseif (ef<0.3 or ei<eu) and mf>0.1 then
		unitName=BuildUWFusion(self)
	end
	--print(tostring('cw2 '..unitName))
	return unitName
end

local function EconomySeaplane(self)
	local unitName=DummyUnitName
	if 	ef>0.9 and ei>1000 and mi>mu then
		unitName=buildEstore2(self)
		print(tostring('s3'))
	elseif mf>0.7 and mi>30  then
		unitName=buildMstore2(self)
		print(tostring('s5'))
	elseif ef>0.8  then
		unitName=buildMconv2UW(self)
		print(tostring('s4'))
	elseif ef>0.5 and mf>0.5 then
		unitName=ConShip(self) 
	end
	--print(tostring('sp '..unitName))
	return unitName
end

local function ConsulAsFactory(self)
	local UnitName=DummyUnitName
	local rnd= math.random(1,9)
	print(tostring('EBEF '.. rnd))
	if 	rnd==1 then UnitName=ConVehicle(self) 
	elseif 	rnd==2 then UnitName=ConShip(self) 
	elseif 	rnd==3 then UnitName=Lvl1BotRaider(self) 
	elseif 	rnd==4 then UnitName=Lvl1AABot(self) 
	elseif 	rnd==5 then UnitName=Lvl2BotArty(self)
	elseif 	rnd==6 then UnitName=spiders(self)
	elseif 	rnd==7 then UnitName=Lv2BotMedium(self)
	elseif 	rnd==8 then UnitName=Lvl1ShipDestroyerOnly(self)
	else UnitName=DummyUnitName
	end
	if UnitName==nil then UnitName = DummyUnitName end
	--print(tostring('EBEF '.. rnd .. ' ' ..UnitName))
	return UnitName
end

local function FreakerAsFactory(self)
	local UnitName=DummyUnitName
	local rnd= math.random(1,9)
	print(tostring('EBEF '.. rnd))
	if 	rnd==1 then UnitName=ConBot(self)
	elseif 	rnd==2 then UnitName=ConShip(self)
	elseif 	rnd==3 then UnitName=Lvl1BotRaider(self)
	elseif 	rnd==4 then UnitName=Lvl1AABot(self)
	elseif 	rnd==5 then UnitName=Lvl2BotRaider(self)
	elseif 	rnd==6 then UnitName=Lv2AmphBot(self)
	elseif 	rnd==7 then UnitName=Lvl1ShipDestroyerOnly(self)
	elseif 	rnd==8 then UnitName=NewCommanders(self)
	else UnitName=DummyUnitName
	end
	if UnitName==nil then UnitName = DummyUnitName end
	--print(tostring('EBEF '.. rnd .. ' ' ..UnitName))
	return UnitName
end

local function CormlsAsFactory(self)
	local UnitName=DummyUnitName
	local rnd= math.random(1,9)
	--print(tostring('ENEF '.. rnd))
	if 	rnd==1 then UnitName=ConShip(self)
	elseif 	rnd==2 then UnitName=ScoutShip(self)
	elseif 	rnd==3 then UnitName=Lvl1ShipDestroyerOnly(self)
	elseif 	rnd==4 then UnitName=Lvl1ShipRaider(self)
	elseif 	rnd==5 then UnitName=Lvl1ShipBattle(self)
	elseif 	rnd==6 then UnitName=Lv2AmphBot(self)	
	else 
		UnitName=DummyUnitName
	
	end
	return UnitName
end
local function NavalEngineerAsFactory(self)
	local UnitName=DummyUnitName
	local rnd= math.random(1,9)
	print(tostring('ENEF '.. rnd))
	if 	rnd==1 then UnitName=ConShip(self)
	elseif 	rnd==2 then UnitName=ScoutShip(self)
	elseif 	rnd==3 then UnitName=Lvl1ShipDestroyerOnly(self)
	elseif 	rnd==4 then UnitName=Lvl1ShipRaider(self)
	elseif 	rnd==5 then UnitName=Lvl1ShipBattle(self)
	elseif 	rnd==6 then UnitName=Lv2AmphBot(self)
	else 
		UnitName=DummyUnitName
	
	end
	--print(tostring('enef '),tostring(UnitName)) 
	return UnitName
end



local function EngineerAsFactory(self)
	local unitName=DummyUnitName
	if ef>0.3 and ef<0.7 and mf>0.3 and mf<0.7 then
		if ai.mySide == CORESideName then
			unitName=FreakerAsFactory(self)
		else
			unitName=ConsulAsFactory(self)
		end
	end
	return unitName
end

-- local function NavalEngineerAsFactory(self)
-- 	local unitName=DummyUnitName
-- 		if ai.mySide == CORESideName then
-- 			unitName=CormlsAsFactory(self)
-- 		else
-- 			unitName=ArmlmsAsFactory(self)
-- 		end
-- 	print(tostring('enef '),tostring(unitName)) 
-- 	return unitName
-- end
	

local function CommanderEconomy(self)
	local here =ai.maphandler:WaterOrGroundHere(self.unit:Internal():GetPosition())
	local unitName = DummyUnitName
	if here then 
		unitName = Economy0(self)
	else
		unitName = EconomyUnderWater(self)
	end
	return unitName
	
end

local function AmphibiousEconomy(self)
	local here =ai.maphandler:WaterOrGroundHere(self.unit:Internal():GetPosition())
	local unitName = DummyUnitName
	if here then 
		unitName = Economy1(self)
	else
		unitName = EconomyUnderWater(self)
	end
	return unitName
	
end
-- mobile construction units:

local anyCommander = {
	CheckMySideIfNeeded,
	BuildAppropriateFactory,
	BuildLLT,
	CommanderEconomy,
	BuildRadar,
	BuildLightAA,
	BuildPopTorpedo,
	BuildSonar,
	
}

local anyConUnit = {
	BuildAppropriateFactory,
        Economy1,
	BuildLLT,
	AATurrets1,
	BuildRadar,
	BuildLvl1Jammer,
	BuildGeo,
	BuildHLT,
	BuildLvl1Plasma,
	BuildHeavyishAA,
	BuildSpecialLT,
	BuildMediumAA,
}

local anyConAmphibious = {
	BuildAppropriateFactory,
	Economy1,
	EconomyUnderWater,
	--AmphibiousEconomy,
	BuildGeo,
	BuildSpecialLT,
	BuildMediumAA,
	BuildRadar,
	BuildLvl1Jammer,
	BuildHLT,
	BuildLvl1Plasma,
	BuildHeavyishAA,
	BuildPopTorpedo,
	BuildFloatLightAA,
	BuildSonar,
	BuildFloatRadar,
	BuildFloatHLT,
	BuildLightTorpedo,
}

local anyConShip = {
	BuildAppropriateFactory,
	EconomyUnderWater,
	BuildFloatLightAA,
	BuildSonar,
	BuildLightTorpedo,
	BuildFloatRadar,
	BuildFloatHLT,
}

local anyAdvConUnit = {
	BuildAppropriateFactory,
	Economy2,
	BuildNukeIfNeeded,
	BuildAdvancedRadar,
	BuildHeavyPlasma,
	BuildAntinuke,
	BuildLvl2PopUp,
	BuildHeavyAA,
	BuildLvl2Plasma,
	BuildTachyon,
	-- BuildTacticalNuke,
	BuildExtraHeavyAA,
	BuildLvl2Jammer,
	BuildMohoGeo,
}


local anyAdvConUnit3 = {
	BuildAppropriateFactory,
	Economy3,
	BuildNukeIfNeeded,
	BuildAdvancedRadar,
	BuildHeavyPlasma,
	BuildAntinuke,
	BuildLvl2PopUp,
	BuildHeavyAA,
	BuildLvl2Plasma,
	BuildTachyon,
	-- BuildTacticalNuke,
	BuildExtraHeavyAA,
	BuildLvl2Jammer,
	BuildMohoGeo,
}


local anyConSeaplane = {
	EconomySeaplane,
	BuildFloatHeavyAA,
	BuildAdvancedSonar,
	BuildHeavyTorpedo,
	BuildAppropriateFactory,
}

local anyAdvConSub = {
	BuildAppropriateFactory,
	EconomyUnderWater2,
	BuildFloatHeavyAA,
	BuildAdvancedSonar,
	BuildHeavyTorpedo,
}

local anyNavalEngineer = {
	BuildAppropriateFactory,
	EconomyNavalEngineer,
	BuildFloatHLT,
	BuildFloatLightAA,
	BuildFloatRadar,
	BuildSonar,
	BuildLightTorpedo,
	NavalEngineerAsFactory,
}

local anyCombatEngineer = {
	BuildAppropriateFactory,
	EconomyBattleEngineer,
	EngineerAsFactory,
	BuildMediumAA,
	BuildAdvancedRadar,
	BuildLvl2Jammer,
	BuildHeavyAA,
	BuildSpecialLTOnly,
	
}

anyFark={
	WindSolar,
	buildMex0,
	BuildMconv1,
	
}

-- factories:

local anyLvl1AirPlant = {
	ScoutAir,
	Lvl1Bomber,
	Lvl1AirRaider,
	ConAir,
	Lvl1Fighter,
	Lvl1AirSupport,
}

local anyLvl1VehPlant = {
	ScoutVeh,
	ConVehicle,
	Lvl1VehRaider,
	Lvl1VehBattle,
	Lvl1AAVeh,
	Lvl1VehArty,
	Lvl1VehBreakthrough,
	lv1VehSupport,
}

local anyLvl1BotLab = {
	ScoutBot,
	ConBot,
	Lvl1BotRaider,
	Lvl1BotBattle,
	Lvl1AABot,
	Lvl1BotBreakthrough,
	RezBot1,
}

local anyLvl1ShipYard = {
	ScoutShip,
	ConShip,
	Lvl1ShipBattle,
	Lvl1ShipRaider,
	RezSub1,
}

local anyHoverPlatform = {
	HoverRaider,
	ConHover,
	HoverBattle,
	HoverBreakthrough,
	HoverMerl,
	AAHover,
}

local anyAmphibiousComplex = {
	AmphibiousRaider,
	ConVehicleAmphibious,
	AmphibiousBattle,
	Lvl1ShipRaider,
	Lvl1AABot,
	Lvl2AABot,
	RezSub1,
	Decoy,
}

local anyLvl2VehPlant = {
	Lvl2VehRaider,
	ConAdvVehicle,
	Lvl2VehBattle,
	Lvl2VehBreakthrough,
	Lvl2VehArty,
	Lvl2VehMerl,
	Lvl2AAVeh,
	Lvl2VehAssist,
	--armst
	--armanni
	--trem
}

local anyLvl2BotLab = {
	Lvl2BotRaider,
	ConAdvBot,
	Lvl2BotBattle,
	Lvl2BotBreakthrough,
	Lvl2BotArty,
	Lvl2BotLongRange,
	Lvl2AABot,
	spiders,
	Decoy,
	Lv2BotMedium,
	Lvl2BotAssist,
}

local anyLvl2AirPlant = {
	Lvl2Bomber,
	Lvl2TorpedoBomber,
	ConAdvAir,
	ScoutAdvAir,
	Lvl2Fighter,
	Lvl2AirRaider,
	MegaAircraft,
}

local anySeaplanePlatform = {
	ConSeaAir,
	ScoutSeaAir,
	SeaBomber,
	SeaTorpedoBomber,
	SeaFighter,
	SeaAirRaider,
}

local anyLvl2ShipYard = {
	Lvl2ShipRaider,
	ConAdvSub,
	Lvl2ShipBattle,
	Lvl2AAShip,
	Lvl2ShipBreakthrough,
	Lvl2ShipMerl,
	Lvl2ShipAssist,
	MegaShip,
}

local anyExperimental = {
	Lvl3Raider,
	Lvl3Battle,
	Lvl3Merl,
	Lvl3Arty,
	Lvl3Breakthrough,
}
local anyUwExperimental = {
	lv3amp,
	lv3hov,
	AmphibiousBattle,
	AmphibiousBreakthrough,
	lv3bigamp,
}

local anyOutmodedLvl1BotLab = {
	ConBot,
	RezBot1,
	ScoutBot,
	Lvl1AABot,
}

local anyOutmodedLvl1VehPlant = {
	Lvl1VehRaiderOutmoded,
	ConVehicle,
	ScoutVeh,
	Lvl1AAVeh,
}

local anyOutmodedLvl1AirPlant = {
	ConAir,
	ScoutAir,
	Lvl1Fighter,
}

local anyOutmodedLvl1ShipYard = {
	ConShip,
	ScoutShip,
}

local anyOutmodedLvl2BotLab = {
	-- Lvl2BotRaider,
	ConAdvBot,
	Lvl2AABot,
	Lvl2BotAssist,
}

local anyOutmodedLvl2VehPlant = {
	-- Lvl2VehRaider,
	Lvl2VehAssist,
	ConAdvVehicle,
	Lvl2AAVeh,
}

local anyLvl1VehPlantForWater = {
	ScoutVeh,
	AmphibiousRaider,
	ConVehicleAmphibious,
	Lvl1AAVeh,
}
local anyNanoQueues = {
	NanoTurret,
}
local anylv1MexTask = {
	BuildUWMex,
	BuildLightTorpedo,
	BuildMex1,
	BuildLLT,
}	
local anylv3GroundEcoTask= {
	lv3GroundEco
}

local anylv1GroundEcoTask= {
	lv1GroundEco
}
-- use these if it's a watery map
wateryTaskqueues = {
	armvp = anyLvl1VehPlantForWater,
	corvp = anyLvl1VehPlantForWater,
	
	
	
}

-- fall back to these when a level 2 factory exists
outmodedTaskqueues = {
	corlab = anyOutmodedLvl1BotLab,
	armlab = anyOutmodedLvl1BotLab,
	corvp = anyOutmodedLvl1VehPlant,
	armvp = anyOutmodedLvl1VehPlant,
	corap = anyOutmodedLvl1AirPlant,
	armap = anyOutmodedLvl1AirPlant,
	corsy = anyOutmodedLvl1ShipYard,
	armsy = anyOutmodedLvl1ShipYard,
	coralab = anyOutmodedLvl2BotLab,
	armalab = anyOutmodedLvl2BotLab,
	coravp = anyOutmodedLvl2VehPlant,
	armavp = anyOutmodedLvl2VehPlant,
}
NanoTurretTaskQueues={
	corcv = anyNanoQueues,
	armcv = anyNanoQueues,
	armcv = anyNanoQueues,
	corcv = anyNanoQueues,
	armca = anyNanoQueues,
	corca = anyNanoQueues,
	armck = anyNanoQueues,
	corck = anyNanoQueues,
	corch = anyNanoQueues,
	armch = anyNanoQueues,
	corfast = anyNanoQueues,
	cormuskrat = anyNanoQueues,
	armbeaver = anyNanoQueues,
	consul = anyNanoQueues,
}
lv1MexSnapper={
	cormuskrat = anylv1MexTask,
	armbeaver = anylv1MexTask,
	
}
lv1GroundEcoBuilders = {
armcv = anylv1GroundEcoTask,
corcv = anylv1GroundEcoTask,
}

lv3GroundEcoBuilders = {
armacv = anylv3GroundEcoTask,
coracv = anylv3GroundEcoTask,
}
-- finally, the taskqueue definitions
taskqueues = {
	corcom = anyCommander,
	armcom = anyCommander,
	corcv = anyConUnit,
	armcv = anyConUnit,
	corck = anyConUnit,
	armck = anyConUnit,
	cormuskrat = anyConAmphibious,
	armbeaver = anyConAmphibious,
	corch = anyConAmphibious,
	armch = anyConAmphibious,
	corca = anyConUnit,
	armca = anyConUnit,
	corack = anyAdvConUnit,
	armack = anyAdvConUnit,
	coracv = anyAdvConUnit3,
	armacv = anyAdvConUnit3,
	coraca = anyAdvConUnit,
	armaca = anyAdvConUnit,
	corcsa = anyConSeaplane,
	armcsa = anyConSeaplane,
	corcs = anyConShip,
	armcs = anyConShip,
	coracsub = anyAdvConSub,
	armacsub = anyAdvConSub,
	cormls = anyNavalEngineer,
	armmls = anyNavalEngineer,
	consul = anyCombatEngineer,
	corfast = anyCombatEngineer,
	corap = anyLvl1AirPlant,
	armap = anyLvl1AirPlant,
	corlab = anyLvl1BotLab,
	armlab = anyLvl1BotLab,
	corvp = anyLvl1VehPlant,
	armvp = anyLvl1VehPlant,
	coralab = anyLvl2BotLab,
	coravp = anyLvl2VehPlant,
	corhp = anyHoverPlatform,
	armhp = anyHoverPlatform,
	corfhp = anyHoverPlatform,
	armfhp = anyHoverPlatform,
	csubpen = anyAmphibiousComplex,
	asubpen = anyAmphibiousComplex,
	armalab = anyLvl2BotLab,
	armavp = anyLvl2VehPlant,
	coraap = anyLvl2AirPlant,
	armaap = anyLvl2AirPlant,
	corplat = anySeaplanePlatform,
	armplat = anySeaplanePlatform,
	corsy = anyLvl1ShipYard,
	armsy = anyLvl1ShipYard,
	corasy = anyLvl2ShipYard,
	armasy = anyLvl2ShipYard,
	corgant = anyExperimental,
	armshltx = anyExperimental,
	corgantuw = anyUwExperimental,
	armshltxuw = anyUwExperimental,
		
	armfark = anyFark,
}