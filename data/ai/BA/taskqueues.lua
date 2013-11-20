--[[
 Task Queues!
]]--

require "unitlists"
require "unittable"

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

function MapLandType()
	if ai ~= nil then
		if ai.mapMobType ~= nil then
			EchoDebug(ai.mapMobType)
			return ai.mapMobType
		else
			game:SendToConsole("map has no land type!") -- if this happens, i've clearly done something wrong
		end
	end
end

local function CheckMySide(self)
	-- fix: moved here so map object is present when it's accessed
	ConUnitPerTypeLimit = math.max(map:SpotCount() / 6, 4)
	ConUnitAdvPerTypeLimit = math.max(ConUnitPerTypeLimit / 2, 2)
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
		local Metal = game:GetResourceByName("Metal")
		if Metal.reserves < 0.5 * Metal.capacity and ai.wreckCount > 0 then
			ai.needToReclaim = true
		else
			ai.needToReclaim = false
		end
		AAUnitPerTypeLimit = math.ceil(Metal.income / 12)
		heavyPlasmaLimit = math.ceil(ai.combatCount / 7)
		nukeLimit = math.ceil(ai.combatCount / 20)

		local attackCounter = ai.attackhandler:GetCounter()
		local couldAttack = ai.couldAttack - ai.factories >= 2 or ai.couldBomb > 2
		local bombingTooExpensive = ai.bomberhandler:GetCounter() == maxBomberCounter
		local attackTooExpensive = attackCounter == maxAttackCounter
		local plentyOfCombatUnits = ai.combatCount > attackCounter * 2.5
		local needUpgrade = plentyOfCombatUnits or couldAttack or bombingTooExpensive or attackTooExpensive

		EchoDebug(ai.totalEnemyThreat .. " " .. ai.totalEnemyImmobileThreat .. " " .. ai.totalEnemyMobileThreat)
		-- build siege units if the enemy is turtling, if a lot of our attackers are getting destroyed, or if we control more than half the metal spots on the map
		needSiege = (ai.totalEnemyImmobileThreat > ai.totalEnemyMobileThreat * 3 and ai.totalEnemyImmobileThreat > 50000) or (attackCounter > maxAttackCounter * 0.85) or (ai.mexCount > #ai.mobNetworkMetals["air"][1] * 0.5)
		ai.needAdvanced = false
		if Metal.income > 12 and ai.factories > 0 and needUpgrade then
			ai.needAdvanced = true
		end
		ai.needExperimental = false
		ai.needNukes = false
		if Metal.income > 50 and ai.haveAdvFactory and needUpgrade and ai.enemyBasePosition then
			local canGetThere = false
			for i, factory in pairs(ai.factoriesAtLevel[ai.maxFactoryLevel]) do
				if ai.maphandler:MobilityNetworkHere("bot", factory.position) == ai.maphandler:MobilityNetworkHere("bot", ai.enemyBasePosition) then
					canGetThere = true
					break
				end
			end
			if not ai.haveExpFactory and canGetThere then
				ai.needExperimental = true
			end
			ai.needNukes = true
		end
		EchoDebug("metal income: " .. Metal.income .. "  combat units: " .. ai.combatCount)
		EchoDebug("need advanced? " .. tostring(ai.needAdvanced) .. "  need experimental? " .. tostring(ai.needExperimental))
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

function IsAntinukeNeeded()
	return ai.needAntinuke
end

function IsNukeNeeded()
	local nuke = ai.needNukes and ai.canNuke
	return nuke
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
	local res = game:GetResourceByName("Energy")
	if res.income < res.usage then
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
	local Energy = game:GetResourceByName("Energy")
	local extraE = Energy.income - Energy.usage
	local Metal = game:GetResourceByName("Metal")
	local extraM = Metal.income - Metal.usage
	local isWater = unitTable[self.unit:Internal():Name()].needsWater
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if extraE > 60 and extraM < 0 and Energy.income > 300 then
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("corfmkr", 8)
			else
				unitName = BuildWithLimitedNumber("armfmkr", 8)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormakr", 8)
			else
				unitName = BuildWithLimitedNumber("armmakr", 8)
			end
		end
	end
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if Energy.reserves >= 0.9 * Energy.capacity and extraE > 100 then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwes", 3)
				else
					unitName = BuildWithLimitedNumber("armuwes", 3)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("corestor", 3)
				else
					unitName = BuildWithLimitedNumber("armestor", 3)
				end
			end
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if Metal.reserves >= 0.9 * Metal.capacity and extraM > 3 then
			if isWater then
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("coruwms", 3)
				else
					unitName = BuildWithLimitedNumber("armuwms", 3)
				end	
			else
				if ai.mySide == CORESideName then
					unitName = BuildWithLimitedNumber("cormstor", 3)
				else
					unitName = BuildWithLimitedNumber("armmstor", 3)
				end
			end
		end
	end

	return unitName
end


-- build advanced conversion or storage
function DoSomethingAdvancedForTheEconomy(self)
	local Energy = game:GetResourceByName("Energy")
	local extraE = Energy.income - Energy.usage
	local Metal = game:GetResourceByName("Metal")
	local extraM = Metal.income - Metal.usage
	local isWater = unitTable[self.unit:Internal():Name()].needsWater
	local unitName = DummyUnitName
	-- maybe we need conversion?
	if extraE > 600 and extraM < 0 and Energy.income > 2000 then
		if isWater then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("armuwmmm", Energy.income / 1000)
			else
				unitName = BuildWithLimitedNumber("armuwmmm", Energy.income / 1000)
			end		
		else
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("cormmkr", Energy.income / 1000)
			else
				unitName = BuildWithLimitedNumber("armmmkr", Energy.income / 1000)
			end
		end
	end
	-- maybe we need storage?
	if unitName == DummyUnitName then
		-- energy storage
		if Energy.reserves >= 0.9 * Energy.capacity and extraE > 1000 then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadves", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadves", 1)
			end	
		end
	end
	if unitName == DummyUnitName then
		-- metal storage
		if Metal.reserves >= 0.9 * Metal.capacity and extraM > 10 then
			if ai.mySide == CORESideName then
				unitName = BuildWithLimitedNumber("coruwadvms", 1)
			else
				unitName = BuildWithLimitedNumber("armuwadvms", 1)
			end	
		end
	end

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
		return BuildWithLimitedNumber(unitName, math.ceil(ai.battleCount * 0.25))
	end
	return DummyUnitName
end

-- uses this on breakthrough units
function BuildDefendIfNeeded(unitName)
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	local mtype = unitTable[unitName].mtype
	if ai.attackhandler:GetCounter(mtype) == maxAttackCounter then
		return unitName
	else
		return DummyUnitName
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
	local output = BuildSiegeIfNeeded(unitName)
	if output == DummyUnitName then
		output = BuildDefendIfNeeded(unitName)
	end
	return output
end

function Lvl1VehBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corlevlr"
		local output = BuildSiegeIfNeeded(unitName)
		if output == DummyUnitName then
			output = BuildDefendIfNeeded(unitName)
		end
		return output
	else
		unitName = "armjanus"
		local output = BuildSiegeIfNeeded(unitName)
		if output == DummyUnitName then
			output = BuildDefendIfNeeded("armstump")
		end
		return output
	end
end

function Lvl2VehBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corgol"
		local output = BuildSiegeIfNeeded(unitName)
		if output == DummyUnitName then
			output = BuildDefendIfNeeded(unitName)
		end
		return output
	else
		unitName = "armmanni"
		local output = BuildSiegeIfNeeded(unitName)
		if output == DummyUnitName then
			output = BuildDefendIfNeeded("armbull")
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
	local output = BuildSiegeIfNeeded(unitName)
	if output == DummyUnitName then
		output = BuildDefendIfNeeded(unitName)
	end
	return output
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
	local output = BuildSiegeIfNeeded(unitName)
	if output == DummyUnitName then
		output = BuildDefendIfNeeded(unitName)
	end
	return output
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
	if ai.mySide == CORESideName then
		return BuildSiegeIfNeeded(BuildWithLimitedNumber("corblackhy", 1))
	else
		return BuildSiegeIfNeeded(BuildWithLimitedNumber("aseadragon", 1))
	end
end

function MegaAircraft()
	if ai.mySide == CORESideName then
		return BuildSiegeIfNeeded(BuildWithLimitedNumber("corcrw", 3))
	else
		local r = math.random(1, 2)
		if r == 1 then
			return BuildSiegeIfNeeded(BuildWithLimitedNumber("armcybr", 8))
		else
			return BuildSiegeIfNeeded(BuildRaiderIfNeeded("blade"))
		end
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
	else
		unitName = BuildWithLimitedNumber("armbanth", 3)
	end
	local output = BuildSiegeIfNeeded(unitName)
	if output == DummyUnitName then
		output = BuildDefendIfNeeded(unitName)
	end
	return output
end

function BuildRaiderIfNeeded(unitName)
	if unitName == DummyUnitName or unitName == nil then return DummyUnitName end
	local mtype = unitTable[unitName].mtype
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
	local unitName = ""
	if ai.mySide == CORESideName then
		return DummyUnitName
	else
		unitName = "armlatnk"
	end
	return BuildRaiderIfNeeded(unitName)
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
		unitName = "armbrawl"
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
	if attackCounter == maxAttackCounter then return DummyUnitName end
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
	if ai.mySide == CORESideName then
		local unitName = "corparrow"
		unitName = BuildSiegeIfNeeded(unitName)
		if unitName == DummyUnitName then
			unitName = BuildDefendIfNeeded(unitName)
		end
		return unitName
	else
		return DummyUnitName
	end
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

-- how many of our own unitName there are in a radius around a position
function CountOwnUnitsInRadius(unitName, pos, radius, maxCount)
	local ownUnits = game:GetFriendlies()
	local unitCount = 0
	-- optimisation: there is always 0 null units on map
	if unitName == DummyUnitName then
		return 0
	end
	for _, u in pairs(ownUnits) do
		if u:Name() == unitName then
			local upos = u:GetPosition()
			if distance(pos, upos) < radius then
				unitCount = unitCount + 1
			end
			-- optimisation: if the limit is already exceeded, don't count further
			if unitCount >= maxCount then
				break
			end
		end
	end
	return unitCount
end

local function CheckAreaLimit(unitName, builder, unitLimit, range)
	-- this is special case, it means the unit will not be built anyway
	if unitName == DummyUnitName then
		return unitName
	end
	local pos = builder:GetPosition()
	if range == nil then range = AreaCheckRange end
	-- now check how many of the wanted unit is nearby
	local NumberOfUnits = CountOwnUnitsInRadius(unitName, pos, range, unitLimit)
	local AllowBuilding = NumberOfUnits < unitLimit
	EchoDebug(""..unitName.." wanted, with range limit of "..unitLimit..", with "..NumberOfUnits.." already there. The check is: "..tostring(AllowBuilding))
	if AllowBuilding then
		return unitName
	else
		return DummyUnitName
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
		unitName = "armpb"
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
		unitName = BuildAAIfNeeded("corfflak")
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
	if not IsTorpedoNeeded() then return DummyUnitName end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsonar"
	else
		unitName = "armsonar"
	end
	return unitName
end

local function BuildAdvancedSonar()
	if not IsTorpedoNeeded() then return DummyUnitName end
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

function Lvl2Fighter()
	local unitName
	if ai.mySide == CORESideName then
		unitName = "corvamp"
	else
		unitName = "armhawk"
	end
	return BuildAAIfNeeded(unitName)
end

local function CheckMySideIfNeeded()
	if ai.mySide == nil then
		EchoDebug("commander: checkmyside")
		return CheckMySide
	else
		return DummyUnitName
	end
end

local function CheckForOwnUnit(name)
	local ownUnits = game:GetFriendlies()
	for _, u in pairs(ownUnits) do
		local un = u:Name()
		if un == name then
			local ut = u:Team()
			if ut == ownTeamID then
				return true
			end
		end
	end
	return false
end

local function BuildAppropriateFactory(self)
	local builder = self.unit:Internal()
	EchoDebug("checking control for " .. builder:Name())
	CheckForMapControl()
	EchoDebug("building appropriate factory..")
	local factories, advanced, experimental = ai.maphandler:WhatFactories(builder)
	if experimental ~= nil and ai.needExperimental then
		return BuildWithLimitedNumber(experimental, 1)
	end
	if advanced ~= nil and ai.needAdvanced then
		return BuildWithLimitedNumber(advanced, 1)
	end
	local unitName = DummyUnitName
	if factories ~= nil then
		EchoDebug(#factories)
		for i, fname in pairs(factories) do
			EchoDebug("trying" .. fname)
			unitName = BuildWithLimitedNumber(fname, 1)
			if unitName ~= DummyUnitName then break end
		end
	end
	EchoDebug(unitName)
	return unitName
end

local function FactoryOrNano(self)
	if ai.factories == 0 then return BuildAppropriateFactory(self) end
	EchoDebug("factories: " .. ai.factories .. "  combat units: " .. ai.combatCount)
	local unitName = DummyUnitName
	if ai.combatCount > 10 or ai.needAdvanced then
		unitName = BuildAppropriateFactory(self)
	end
	if ai.combatCount > 3 and unitName == DummyUnitName then
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
	return BuildWithLimitedNumber(unitName, 1)
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
	TidalIfTidal,
	BuildLLT,
	BuildRadar,
	BuildSonar,
	BuildLightAA,
	BuildDepthCharge,
	DoSomethingForTheEconomy,
}

local anyConUnit = {
	BuildAppropriateFactory,
	NanoTurret,
	BuildLLT,
	BuildSpecialLT,
	BuildMediumAA,
	BuildRadar,
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
	WindSolar,
	SolarAdv,
	FactoryOrNano,
	BuildHLT,
	BuildLvl1Plasma,
	DoSomethingForTheEconomy,
	BuildHeavyishAA,
	BuildMex,
	BuildLightTorpedo,
	BuildFloatLightAA,
	BuildSonar,
	BuildLightTorpedo,
	BuildFloatRadar,
	TidalIfTidal,
	BuildFloatHLT,
	DoSomethingForTheEconomy,
	BuildDepthCharge,
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
	BuildDepthCharge,
}

local anyAdvConUnit = {
	BuildLvl2PopUp,
	BuildHeavyAA,
	BuildAntinuke,
	BuildLvl2Plasma,
	BuildTachyon,
	BuildHeavyPlasma,
	BuildFusion,
	BuildAdvancedRadar,
	BuildAppropriateFactory,
	BuildNukeIfNeeded,
	BuildExtraHeavyAA,
	BuildMohoGeo,
	BuildMohoMex,
	DoSomethingAdvancedForTheEconomy,
}

local anyAdvConSub = {
	BuildUWMohoMex,
	BuildFloatHeavyAA,
	BuildUWFusion,
	BuildAdvancedSonar,
	BuildHeavyTorpedo,
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
	ConAdvAir,
	ScoutAdvAir,
	Lvl2Fighter,
	Lvl2AirRaider,
	MegaAircraft,
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
	Lvl2BotRaider,
	ConAdvBot,
	Lvl2AABot,
	Lvl2BotAssist,
}

local anyOutmodedLvl2VehPlant = {
	Lvl2VehRaider,
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
	armalab = anyLvl2BotLab,
	armavp = anyLvl2VehPlant,
	coraap = anyLvl2AirPlant,
	armaap = anyLvl2AirPlant,
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