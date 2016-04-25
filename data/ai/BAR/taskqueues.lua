--[[
 Task Queues!
]]--

shard_include("common")
shard_include("taskAir")
shard_include("taskBot")
shard_include("taskVeh")
shard_include("taskShp")
shard_include("taskHov")
shard_include("taskBuild")
shard_include("taskEco")
local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("Taskqueues: " .. inStr)
	end
end
taskParams = {}
random = math.random
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
		local controlMetalSpots = #ai.mexCount > #ai.mobNetworkMetals["air"][1] * 0.4
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

function Lvl2BotCorRaiderArmBattle(self)
	if ai.mySide == CORESideName then
		return Lvl2BotRaider(self)
	else
		return Lvl2BotBattle(self)
	end
end

local function WindSolarTidal(self)
	LandOrWater(self, WindSolar(), TidalIfTidal())
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


function GroundDefenseIfNeeded(unitName, builder)
	if not ai.needGroundDefense then
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

function CheckMySideIfNeeded()
	if ai.mySide == nil then
		EchoDebug("commander: checkmyside")
		return CheckMySide
	else
		return DummyUnitName
	end
end

function BuildAppropriateFactory()
	return FactoryUnitName
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


-- mobile construction units:

local anyCommander = {
	CheckMySideIfNeeded,
	BuildMex,
	BuildAppropriateFactory,
	WindSolar,
	BuildLLT,
	BuildRadar,
	BuildLightAA,
	DoSomethingForTheEconomy,
	TidalIfTidal,
	BuildPopTorpedo,
	BuildSonar,
}

local anyConUnit = {
	BuildAppropriateFactory,
	NanoTurret,
	BuildLLT,
	BuildSpecialLT,
	BuildMediumAA,
	BuildRadar,
	BuildLvl1Jammer,
	WindSolar,
	BuildGeo,
	SolarAdv,
	BuildHLT,
	BuildLvl1Plasma,
	DoSomethingForTheEconomy,
	BuildHeavyishAA,
	BuildMex,
}

local anyConAmphibious = {
	BuildGeo,
	BuildSpecialLT,
	BuildMediumAA,
	BuildRadar,
	BuildLvl1Jammer,
	WindSolar,
	SolarAdv,
	FactoryOrNano,
	BuildHLT,
	BuildLvl1Plasma,
	DoSomethingForTheEconomy,
	BuildHeavyishAA,
	BuildMex,
	BuildPopTorpedo,
	BuildFloatLightAA,
	BuildSonar,
	BuildFloatRadar,
	TidalIfTidal,
	BuildFloatHLT,
	DoSomethingForTheEconomy,
}

local anyConShip = {
	BuildUWMex,
	BuildFloatLightAA,
	BuildSonar,
	BuildLightTorpedo,
	BuildFloatRadar,
	TidalIfTidal,
	BuildAppropriateFactory,
	BuildFloatHLT,
	DoSomethingForTheEconomy,
}

local anyAdvConUnit = {
	BuildAppropriateFactory,
	BuildFusion,
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
	BuildMohoMex,
	-- DoSomethingAdvancedForTheEconomy,
}

local anyConSeaplane = {
	BuildUWMohoMex,
	BuildFloatHeavyAA,
	BuildUWFusion,
	BuildAdvancedSonar,
	BuildHeavyTorpedo,
	BuildAppropriateFactory,
	-- DoSomethingAdvancedForTheEconomy,
}

local anyAdvConSub = {
	BuildUWMohoMex,
	BuildFloatHeavyAA,
	BuildUWFusion,
	BuildAdvancedSonar,
	BuildHeavyTorpedo,
	-- DoSomethingAdvancedForTheEconomy,
}

local anyNavalEngineer = {
	BuildFloatHLT,
	BuildFloatLightAA,
	BuildAppropriateFactory,
	Lvl1ShipBattle,
	BuildFloatRadar,
	TidalIfTidal,
	BuildUWMex,
	BuildSonar,
	Lvl1ShipRaider,
	Conship,
	ScoutShip,
	BuildLightTorpedo,
}

local anyCombatEngineer = {
	BuildAppropriateFactory,
	NanoTurret,
	Solar,
	BuildMediumAA,
	BuildAdvancedRadar,
	BuildLvl2Jammer,
	BuildLvl2PopUp,
	BuildHeavyAA,
	BuildSpecialLTOnly,
	BuildLvl2Plasma,
	ConCoreBotArmVehicle,
	Lvl2BotCorRaiderArmBattle,
	Lvl1AABot,
	ConShip,
	Lvl1ShipDestroyerOnly,
	BuildMex,
}


-- factories:

local anyLvl1AirPlant = {
	ScoutAir,
	Lvl1Bomber,
	Lvl1AirRaider,
	ConAir,
	Lvl1Fighter,
}

local anyLvl1VehPlant = {
	ScoutVeh,
	ConVehicle,
	Lvl1VehRaider,
	Lvl1VehBattle,
	Lvl1AAVeh,
	Lvl1VehArty,
	Lvl1VehBreakthrough,
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
}

local anyLvl2BotLab = {
	Lvl2BotRaider,
	ConAdvBot,
	Lvl2BotBattle,
	Lvl2BotBreakthrough,
	Lvl2BotArty,
	Lvl2BotMerl,
	Lvl2AABot,
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
	SeaBomber,
	SeaTorpedoBomber,
	ConSeaAir,
	ScoutSeaAir,
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
	coracv = anyAdvConUnit,
	armacv = anyAdvConUnit,
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
	armfark = {
		WindSolar,
		BuildMex,
	}
}