--[[
 Task Queues!
]]--

shard_include "common"


local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("Taskqueues: " .. inStr)
	end
end

local random = math.random
math.randomseed( os.time() + game:GetTeamID() )
random(); random(); random()

local needAA = false
local needShields = false
local needAntinuke = false
local needtorpedo = false
local needGroundDefense = true

-- do we need siege equipment such as artillery and merl?
local needSiege = false

local heavyPlasmaLimit = 3 -- changes with CheckForMapControl
local AAUnitPerTypeLimit = 3 -- changes with CheckForMapControl
local nukeLimit = 1 -- changes with CheckForMapControl
local tacticalNukeLimit = 1 -- changes with CheckForMapControl

local lastCheckFrame = 0
local lastSiegeCheckFrame = 0

-- build ranges to check for things
local AreaCheckRange = 1500

local tidalPower = 0

local averageWind = 0
local needWind = false
local windRatio = 1

local needAmphibiousCons = false

local minDefenseNetworkSize = 100000

local function MapHasWater()
	return (ai.waterMap or ai.hasUWSpots) or false
end

local function CheckMySide(self)
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
local function MapHasUnderwaterMetal()
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

function BuildMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cormex"
	else
		unitName = "armmex"
	end
	return unitName
end

function BuildUWMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "coruwmex"
	else
		unitName = "armuwmex"
	end
	return unitName
end

function BuildMohoMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cormoho"
	else
		unitName = "armmoho"
	end
	return unitName
end

function BuildUWMohoMex()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "coruwmme"
	else
		unitName = "armuwmme"
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

function TidalIfTidal(self)
	local unitName = DummyUnitName
	EchoDebug("tidal power is " .. tidalPower)
	if tidalPower >= 10 then
		if ai.mySide == CORESideName then
			unitName = "cortide"
		else
			unitName = "armtide"
		end
	end
	return unitName
end

-- build conversion or storage
function DoSomethingForTheEconomy(self)
	local highEnergy = ai.Energy.full > 0.9
	local lowEnergy = ai.Energy.full < 0.1
	local highMetal = ai.Metal.full > 0.9
	local lowMetal = ai.Metal.full < 0.1
	local isWater = unitTable[self.unit:Internal():Name()].needsWater
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if ai.Energy.extra > 80 and highEnergy and lowMetal and ai.Metal.extra < 0 and ai.Energy.income > 300 then
		local converterLimit = math.min(math.floor(ai.Energy.income / 200), 4)
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("corfmkr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armfmkr", converterLimit)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormakr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armmakr", converterLimit)
			end
		end
	end
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if ai.Energy.extra > 150 and highEnergy and not lowMetal then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwes", 2)
				else
					unitName = BuildWithLimitedNumber("armuwes", 2)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("corestor", 2)
				else
					unitName = BuildWithLimitedNumber("armestor", 2)
				end
			end
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if ai.Metal.extra > 5 and highMetal and highEnergy then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwms", 2)
				else
					unitName = BuildWithLimitedNumber("armuwms", 2)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("cormstor", 2)
				else
					unitName = BuildWithLimitedNumber("armmstor", 2)
				end
			end
		end
	end

	return unitName
end


-- build advanced conversion or storage
function DoSomethingAdvancedForTheEconomy(self)
	local highEnergy = ai.Energy.full > 0.9
	local lowEnergy = ai.Energy.full < 0.1
	local highMetal = ai.Metal.full > 0.9
	local lowMetal = ai.Metal.full < 0.1
	local unitName = self.unit:Internal():Name()
	local isWater = unitTable[unitName].needsWater or seaplaneConList[unitName]
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if ai.Energy.extra > 800 and highEnergy and lowMetal and ai.Metal.extra < 0 and ai.Energy.income > 2000 then
		local converterLimit = math.floor(ai.Energy.income / 1000)
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("armuwmmm", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armuwmmm", converterLimit)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormmkr", converterLimit)
			else
				unitName = BuildWithLimitedNumber("armmmkr", converterLimit)
			end
		end
	end
	-- building big storage is a waste
	--[[
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if ai.Energy.extra > 1500 and highEnergy and not lowMetal then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadves", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadves", 1)
			end	
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if ai.Metal.extra > 25 and highMetal and highEnergy then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadvms", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadvms", 1)
			end	
		end
	end
	]]--

	return unitName
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

function Lvl1VehArty(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corwolv"
	else
		unitName = "tawf013"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl1BotBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corthud"
	else
		unitName = "armwar"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl1VehBreakthrough(self)
	if ai.mySide == CORESideName then
		return BuildBreakthroughIfNeeded("corlevlr")
	else
		-- armjanus isn't very a very good defense unit by itself
		local output = BuildSiegeIfNeeded("armjanus")
		if output == DummyUnitName then
			output = BuildBreakthroughIfNeeded("armstump")
		end
		return output
	end
end

function Lvl2VehBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		return BuildBreakthroughIfNeeded("corgol")
	else
		-- armmanni isn't very a very good defense unit by itself
		local output = BuildSiegeIfNeeded("armmanni")
		if output == DummyUnitName then
			output = BuildBreakthroughIfNeeded("armbull")
		end
		return output
	end
end

function Lvl2BotBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsumo"
	else
		unitName = "armfboy"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl2BotArty(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormort"
	else
		unitName = "armfido"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2BotMerl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corhrk"
	else
		return DummyUnitName
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2VehArty(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormart"
	else
		unitName = "armmart"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2VehMerl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corvroc"
	else
		unitName = "armmerl"
	end
	return BuildSiegeIfNeeded(unitName)
end

function HoverMerl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormh"
	else
		unitName = "armmh"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2ShipBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corbats"
	else
		unitName = "armbats"
	end
	return BuildBreakthroughIfNeeded(unitName)
end

function Lvl2ShipMerl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cormship"
	else
		unitName = "armmship"
	end
	return BuildSiegeIfNeeded(unitName)
end

function MegaShip()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corblackhy"
	else
		unitName = "aseadragon"
	end
	return BuildBreakthroughIfNeeded(BuildWithLimitedNumber(unitName, 1))
end

function MegaAircraft()
	if ai.mySide == CORESideName then
		return BuildBreakthroughIfNeeded("corcrw")
	else
		return BuildBreakthroughIfNeeded("armcybr")
	end
end

function Lvl3Merl(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "armraven"
	else
		unitName = DummyUnitName
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl3Arty(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "shiva"
	else
		unitName = "armshock"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl3Breakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildWithLimitedNumber("corkrog", 1)
		if unitName == DummyUnitName then
			unitName = BuildWithLimitedNumber("gorg", 2)
		end
		if unitName == DummyUnitName then
			unitName = "corkarg"
		end
	else
		unitName = BuildWithLimitedNumber("armbanth", 5)
		if unitName == DummyUnitName then
			unitName = "armraz"
		end
	end
	return BuildBreakthroughIfNeeded(unitName)
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

function Lvl1VehRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corgator"
	else
		unitName = "armflash"
	end
	return BuildRaiderIfNeeded(unitName)
end

-- because core doesn't have a lvl2 vehicle raider or a lvl3 raider
function Lvl1VehRaiderOutmoded(self)
	if ai.mySide == CORESideName then
		return BuildRaiderIfNeeded("corgator")
	else
		return DummyUnitName
	end
end


function Lvl1BotRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corak"
	else
		unitName = "armpw"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl1ShipRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsub"
	else
		unitName = "armsub"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl1AirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "bladew"
	else
		unitName = "armkam"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl2VehRaider(self)
	if ai.mySide == CORESideName then
		return DummyUnitName
	else
		return BuildRaiderIfNeeded("armlatnk")
	end
end

function Lvl2BotRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corpyro"
	else
		unitName = "armfast"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl2ShipRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corshark"
	else
		unitName = "armsubk"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl2AirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corape"
	else
		-- spedical case: arm has an ubergunship
		local raidCounter = ai.raidhandler:GetCounter("air")
		if raidCounter < baseRaidCounter and raidCounter > minRaidCounter then
			return "blade"
		else
			unitName = "armbrawl"
		end
	end
	return BuildRaiderIfNeeded(unitName)
end

function HoverRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsh"
	else
		unitName = "armsh"
	end
	return BuildRaiderIfNeeded(unitName)
end

function AmphibiousRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corgarp"
	else
		unitName = "armpincer"
	end
	return BuildRaiderIfNeeded(unitName)
end

function Lvl3Raider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = DummyUnitName
	else
		unitName = "marauder"
	end
	return BuildRaiderIfNeeded(unitName)
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

function Lvl2BotCorRaiderArmArty(self)
	if ai.mySide == CORESideName then
		return Lvl2BotRaider(self)
	else
		return Lvl2BotArty(self)
	end
end

function Lvl1VehBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corraid"
	else
		unitName = "armstump"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl1BotBattle(self)
	local unitName = ""
	local r = math.random(1, 2)
	if r == 1 then
		if ai.mySide == CORESideName then
			unitName = "corthud"
		else
			unitName = "armham"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corstorm"
		else
			unitName = "armrock"
		end
	end
	return BuildBattleIfNeeded(unitName)
end

function HoverBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsnap"
	else
		unitName = "armanac"
	end
	return BuildBattleIfNeeded(unitName)
end

function HoverBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "nsaclash"
	else
		unitName = "armanac"
	end
	BuildBreakthroughIfNeeded(unitName)
end

function AmphibiousBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corseal"
	else
		unitName = "armcroc"
	end
	return BuildBattleIfNeeded(unitName)
end

function AmphibiousBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corparrow"
	else
		unitName = "armcroc"
	end
	BuildBreakthroughIfNeeded(unitName)
end

function Lvl1ShipDestroyerOnly(self)
	if ai.combatCount > 12 then
		if ai.mySide == CORESideName then
			unitName = "corroy"
		else
			unitName = "armroy"
		end
		return BuildBattleIfNeeded(unitName)
	end
end

function Lvl1ShipBattle(self)
	local unitName = ""
	local r = 1
	if ai.combatCount > 12 then r = 2 end -- only build destroyers if you've already got quite a few units (combat = scouts + raiders + battle)
	if r == 1 then
		if ai.mySide == CORESideName then
			unitName = "coresupp"
		else
			unitName = "decade"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corroy"
		else
			unitName = "armroy"
		end
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl2VehBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "correap"
	else
		unitName = "armbull"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl2BotBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcan"
	else
		unitName = "armzeus"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl2ShipBattle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcrus"
	else
		unitName = "armcrus"
	end
	return BuildBattleIfNeeded(unitName)
end

function Lvl3Battle(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corkarg"
	else
		unitName = "armraz"
	end
	return BuildBattleIfNeeded(unitName)
end

function WindSolar()
	local wind = false
	if needWind then
		if windRatio == 1 then
			wind = true
		else
			local r = math.random()
			if r < windRatio then wind = true end
		end
	end
	if wind then
		if ai.mySide == CORESideName then
			return "corwin"
		else
			return "armwin"
		end
	else
		if ai.mySide == CORESideName then
			return "corsolar"
		else
			return "armsolar"
		end
	end
end

function Solar()
	if ai.mySide == CORESideName then
		return "corsolar"
	else
		return "armsolar"
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

local function SolarAdv()
	if ai.mySide == CORESideName then
		return "coradvsol"
	else
		return "armadvsol"
	end
end

local function BuildGeo()
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "corgeo"
	else
		return "armgeo"
	end
end

local function BuildMohoGeo(self)
	-- don't attempt if there are no spots on the map
	if not ai.mapHasGeothermal then
		return DummyUnitName
	end
	if ai.mySide == CORESideName then
		return "cmgeo"
	else
		return "amgeo"
	end
	-- will turn into a safe geothermal or a geothermal plasma battery if too close to a factory
end

local function BuildFusion()
	if ai.mySide == CORESideName then
		return "corfus"
	else
		return "armfus"
	end
	-- will become cafus and aafus in CategoryEconFilter in TaskQueueBehaviour if energy income is higher than 4000
end

local function BuildUWFusion()
	if ai.mySide == CORESideName then
		return "coruwfus"
	else
		return "armuwfus"
	end
end

local function Lvl1AABot()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corcrash")
	else
		return BuildAAIfNeeded("armjeth")
	end
end

local function Lvl2AABot()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("coraak")
	else
		return BuildAAIfNeeded("armaak")
	end
end

local function Lvl1AAVeh()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("cormist")
	else
		return BuildAAIfNeeded("armsam")
	end
end

local function Lvl2AAVeh()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corsent")
	else
		return BuildAAIfNeeded("armyork")
	end
end

local function Lvl2AAShip()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corarch")
	else
		return BuildAAIfNeeded("armaas")
	end
end

local function AAHover()
	if ai.mySide == CORESideName then
		return BuildAAIfNeeded("corah")
	else
		return BuildAAIfNeeded("armah")
	end
end

local function ConVehicle()
	local unitName
	if needAmphibiousCons then
		if ai.mySide == CORESideName then
			unitName = "cormuskrat"
		else
			unitName = "armbeaver"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "corcv"
		else
			unitName = "armcv"
		end
	end
	return BuildWithLimitedNumber(unitName, ConUnitPerTypeLimit)
end

local function ConVehicleAmphibious()
	if ai.mySide == CORESideName then
		unitName = "cormuskrat"
	else
		unitName = "armbeaver"
	end
	return BuildWithLimitedNumber(unitName, ConUnitAdvPerTypeLimit)
end

local function ConAdvVehicle()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("coracv", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armacv", ConUnitAdvPerTypeLimit)
	end
end

local function ConBot()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corck", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armck", ConUnitPerTypeLimit)
	end
end

local function ConCoreBotArmVehicle()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corck", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armcv", ConUnitPerTypeLimit)
	end
end

local function ConAdvBot()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corack", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armack", ConUnitAdvPerTypeLimit)
	end
end

local function ConAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corca", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armca", ConUnitPerTypeLimit)
	end
end

local function ConAdvAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("coraca", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armaca", ConUnitAdvPerTypeLimit)
	end
end

local function ConSeaAir()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corcsa", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armcsa", ConUnitPerTypeLimit)
	end
end

local function ConShip()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corcs", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armcs", ConUnitPerTypeLimit)
	end
end

local function ConAdvSub()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("coracsub", ConUnitAdvPerTypeLimit)
	else
		return BuildWithLimitedNumber("armacsub", ConUnitAdvPerTypeLimit)
	end
end

local function ConHover()
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber("corch", ConUnitPerTypeLimit)
	else
		return BuildWithLimitedNumber("armch", ConUnitPerTypeLimit)
	end
end

local function GroundDefenseIfNeeded(unitName, builder)
	if not ai.needGroundDefense then
		return DummyUnitName
	else
		return unitName
	end
end

function BuildShield()
	if IsShieldNeeded() then
		local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corgate"
		else
			unitName = "armgate"
		end
		return unitName
	end
	return DummyUnitName
end

function BuildAntinuke()
	if IsAntinukeNeeded() then
		local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corfmd"
		else
			unitName = "armamd"
		end
		return unitName
	end
	return DummyUnitName
end

function BuildNuke()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsilo"
	else
		unitName = "armsilo"
	end
	return BuildWithLimitedNumber(unitName, nukeLimit)
end

function BuildNukeIfNeeded()
	if IsNukeNeeded() then
		return BuildNuke()
	end
end

function BuildTacticalNuke()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cortron"
	else
		unitName = "armemp"
	end
	return BuildWithLimitedNumber(unitName, tacticalNukeLimit)
end

local function BuildLvl1Plasma()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corpun"
	else
		unitName = "armguard"
	end
	return unitName
end

local function BuildLvl2Plasma()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cortoast"
	else
		unitName = "armamb"
	end
	return unitName
end

local function BuildHeavyPlasma()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corint"
	else
		unitName = "armbrtha"
	end
	return BuildWithLimitedNumber(unitName, heavyPlasmaLimit)
end

local function BuildLLT(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corllt"
	else
		unitName = "armllt"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildSpecialLT(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if IsAANeeded() then
		-- pop-up turrets are protected against bombs
		if ai.mySide == CORESideName then
			unitName = "cormaw"
		else
			unitName = "armclaw"
		end
	else
		if ai.mySide == CORESideName then
			unitName = "hllt"
		else
			unitName = "tawf001"
		end
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildSpecialLTOnly(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "hllt"
	else
		unitName = "tawf001"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildFloatHLT(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corfhlt"
	else
		unitName = "armfhlt"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildHLT(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corhlt"
	else
		unitName = "armhlt"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildLvl2PopUp(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corvipe"
	else
		unitName = "armamb"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildTachyon(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cordoom"
	else
		unitName = "armanni"
	end
	local unit = self.unit:Internal()
	return GroundDefenseIfNeeded(unitName, unit)
end

local function BuildDepthCharge(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cordl"
	else
		unitName = "armdl"
	end
	return BuildTorpedoIfNeeded(unitName)
end


local function BuildLightTorpedo(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cortl"
	else
		unitName = "armtl"
	end
	return BuildTorpedoIfNeeded(unitName)
end

local function BuildPopTorpedo(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corptl"
	else
		unitName = "armptl"
	end
	return BuildTorpedoIfNeeded(unitName)
end

local function BuildHeavyTorpedo(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "coratl"
	else
		unitName = "armatl"
	end
	return BuildTorpedoIfNeeded(unitName)
end


-- build AA in area only if there's not enough of it there already
local function BuildLightAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corrl")
	else
		unitName = BuildAAIfNeeded("armrl")
	end
	return unitName
end

local function BuildFloatLightAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corfrt")
	else
		unitName = BuildAAIfNeeded("armfrt")
	end
	return unitName
end

local function BuildMediumAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("madsam")
	else
		unitName = BuildAAIfNeeded("packo")
	end
	return unitName
end

local function BuildHeavyishAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corerad")
	else
		unitName = BuildAAIfNeeded("armcir")
	end
	return unitName
end

local function BuildHeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corflak")
	else
		unitName = BuildAAIfNeeded("armflak")
	end
	return unitName
end

local function BuildFloatHeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corenaa")
	else
		unitName = BuildAAIfNeeded("armfflak")
	end
	return unitName
end

local function BuildExtraHeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("screamer")
	else
		unitName = BuildAAIfNeeded("mercury")
	end
	return unitName
end

local function BuildSonar()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsonar"
	else
		unitName = "armsonar"
	end
	return unitName
end

local function BuildAdvancedSonar()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corason"
	else
		unitName = "armason"
	end
	return unitName
end


local function BuildRadar()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corrad"
	else
		unitName = "armrad"
	end
	return unitName
end

local function BuildFloatRadar()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corfrad"
	else
		unitName = "armfrad"
	end
	return unitName
end

local function BuildAdvancedRadar()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corarad"
	else
		unitName = "armarad"
	end
	return unitName
end

local function BuildLvl1Jammer()
	if not IsJammerNeeded() then return DummyUnitName end
	if ai.mySide == CORESideName then
		return "corjamt"
	else
		return "armjamt"
	end
end

local function BuildLvl2Jammer()
	if not IsJammerNeeded() then return DummyUnitName end
	if ai.mySide == CORESideName then
		return "corshroud"
	else
		return "armveil"
	end
end

local function NanoTurret()
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cornanotc"
	else
		unitName = "armnanotc"
	end
	return BuildWithLimitedNumber(unitName, ai.factories * 12)
end

local function AirRepairPadIfNeeded()
	local tmpUnitName = DummyUnitName

	-- only make air pads if the team has at least 1 air fac
	if CountOwnUnits("corap") > 0 or CountOwnUnits("armap") > 0 or CountOwnUnits("coraap") > 0 or CountOwnUnits("armaap") > 0 then
		if ai.mySide == CORESideName then
			tmpUnitName = "corasp"
		else
			tmpUnitName = "armasp"
		end
	end
	
	return BuildWithLimitedNumber(tmpUnitName, ConUnitPerTypeLimit)
end

local function corDebug(self)
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

function Lvl1Bomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corshad"
	else
		unitName = "armthund"
	end
	return BuildBomberIfNeeded(unitName)
end

function Lvl1Fighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corveng"
	else
		unitName = "armfig"
	end
	return BuildAAIfNeeded(unitName)
end

function Lvl2Bomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corhurc"
	else
		unitName = "armpnix"
	end
	return BuildBomberIfNeeded(unitName)
end

function Lvl2TorpedoBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cortitan"
	else
		unitName = "armlance"
	end
	return BuildTorpedoBomberIfNeeded(unitName)
end

function Lvl2Fighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corvamp"
	else
		unitName = "armhawk"
	end
	return BuildAAIfNeeded(unitName)
end

function SeaBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corsb"
	else
		unitName = "armsb"
	end
	return BuildBomberIfNeeded(unitName)
end

function SeaTorpedoBomber()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corseap"
	else
		unitName = "armseap"
	end
	return BuildTorpedoBomberIfNeeded(unitName)
end

function SeaFighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corsfig"
	else
		unitName = "armsfig"
	end
	return BuildAAIfNeeded(unitName)
end

function SeaAirRaider(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corcut"
	else
		unitName = "armsaber"
	end
	return BuildRaiderIfNeeded(unitName)
end

local function CheckMySideIfNeeded()
	if ai.mySide == nil then
		EchoDebug("commander: checkmyside")
		return CheckMySide
	else
		return DummyUnitName
	end
end

local function BuildAppropriateFactory()
	return FactoryUnitName
end

local function FactoryOrNano(self)
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

local function LandOrWater(self, landName, waterName)
	local builder = self.unit:Internal()
	local bpos = builder:GetPosition()
	local waterNet = ai.maphandler:MobilityNetworkSizeHere("shp", bpos)
	if waterNet ~= nil then
		return waterName
	else
		return landName
	end
end

local function RezBot1()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "cornecro"
	else
		unitName = "armrectr"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function ScoutBot()
	local unitName
	if ai.mySide == CORESideName then
		return DummyUnitName
	else
		unitName = "armflea"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function ScoutVeh()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corfav"
	else
		unitName = "armfav"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function ScoutAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corfink"
	else
		unitName = "armpeep"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function ScoutShip()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corpt"
	else
		unitName = "armpt"
	end
	local scout = BuildWithLimitedNumber(unitName, 1)
	if scout == DummyUnitName then
		return BuildAAIfNeeded(unitName)
	else
		return unitName
	end
end

local function ScoutAdvAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corawac"
	else
		unitName = "armawac"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function ScoutSeaAir()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corhunt"
	else
		unitName = "armsehak"
	end
	return BuildWithLimitedNumber(unitName, 1)
end

local function Lvl2BotAssist()
	if ai.mySide == CORESideName then
		return "corfast"
	else
		return "armfark"
	end
end

local function Lvl2VehAssist()
	if ai.mySide == CORESideName then
		return DummyUnitName
	else
		return "consul"
	end
end

local function Lvl2ShipAssist()
	if ai.mySide == CORESideName then
		return "cormls"
	else
		return "armmls"
	end
end

-- end of functions


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
	Lvl2BotCorRaiderArmArty,
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