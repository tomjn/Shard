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
local needNukes = false

-- do we need siege equipment such as artillery and merl?
local needSiege = false

local AAUnitPerTypeLimit = 3

local lastCheckFrame = 0
local lastSiegeCheckFrame = 0

-- build ranges to check for things
local AreaCheckRange = 1500

local tidalPower = 0
local averageWind = 0

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
	game:SendToConsole("per-type construction unit limit: " .. ConUnitPerTypeLimit)
	minDefenseNetworkSize = ai.mobilityGridArea / 4 
	-- set the averageWind
	if averageWind == 0 then averageWind = map:AverageWind() end
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

function CheckForDangers()
	-- don't check too soon after previous check
	if (lastCheckFrame + 300) < game:Frame() then
		needAA = false
		needShields = false
		needAntinuke = false
		needTorpedo = false
		lastCheckFrame = game:Frame()
		local enemies = game:GetEnemies()
		if enemies == nil then
			return
		end
		for _, enemyUnit in pairs(enemies) do
			if ai.loshandler:IsKnownEnemy(enemyUnit) > 1 then
				local un = enemyUnit:Name()
				if unitTable[un].mtype == "air" and unitTable[un].groundRange > 0 then
					needAA = true
					EchoDebug("Spotted "..un.." enemy unit, now I need AA!")
				else
					for _, ut in pairs(airFacList) do
						if un == ut then
							needAA = true
							EchoDebug("Spotted "..un.." enemy unit, now I need AA!")
							break
						end
					end
				end
				for _, ut in pairs(bigPlasmaList) do
					if un == ut then
						needShields = true
						EchoDebug("Spotted "..un.." enemy unit, now I need plasma shields!")
						break
					end
				end
				for _, ut in pairs(nukeList) do
					if un == ut then
						needAntinuke = true
						EchoDebug("Spotted "..un.." enemy unit, now I need antinukes!")
						break
					end
				end
				if unitTable[un].needsWater and enemyUnit:WeaponCount() > 0 then
					needTorpedo = true
					EchoDebug("Spotted "..un.." enemy unit, now I need torpedos!")
				else
					for _, ut in pairs(subFacList) do
						if un == ut then
							needTorpedo = true
							EchoDebug("Spotted "..un.." enemy unit, now I need torpedos!")
							break
						end
					end
				end
				if needAA and needShields and needAntinuke and needTorpedo then
					break
				end
			end
		end
		ai.needAA = needAA
		ai.needShields = needShields
		ai.needAntinuke = needAntinuke
		ai.needTorpedo = needTorpedo
	end
end

-- check how much of the map our alliance controls
-- (in terms of mex spots)
-- if we have half or more, it's time to make siege units - base assault time
function CheckForMapControl()
	local f = game:Frame()
	if (lastSiegeCheckFrame + 240) < f then
		local friends = game:GetFriendlies()
		local totalExtractors = map:SpotCount()
		local friendlyExtractors = 0
		ai.haveAdvFactory = false
		ai.haveExpFactory = false
		for _, u in pairs(friends) do
			if u ~= nil then
				local un = u:Name()
				local ut = game:GetTypeByName(un)
				if ut:Extractor() then
					friendlyExtractors = friendlyExtractors + 1
				end
				if advFactories[un] then ai.haveAdvFactory = true end
				if expFactories[un] then ai.haveExpFactory = true end
			end
		end
		if totalExtractors == 0 then
			needSiege = true
		else
			needSiege = (friendlyExtractors / totalExtractors >= 0.5)
		end
		lastSiegeCheckFrame = f
		local Metal = game:GetResourceByName("Metal")
		if Metal.reserves < 0.5 * Metal.capacity and ai.wreckCount > 0 then
			ai.needToReclaim = true
		else
			ai.needToReclaim = false
		end
		AAUnitPerTypeLimit = math.ceil(Metal.income / 12)
		-- game:SendToConsole("bomber counter: " .. ai.bomberhandler:GetCounter() .. "/" .. maxBomberCounter .. "  attack counter: " .. ai.attackhandler:GetCounter() .. "/" .. maxAttackCounter)
		ai.needAdvanced = false
		local attackCounter = ai.attackhandler:GetCounter()
		local couldAttack = ai.couldAttack - ai.factories >= 1 or ai.couldBomb > 1
		if Metal.income > 12 and ai.factories > 0 then
			if couldAttack or ai.bomberhandler:GetCounter() == maxBomberCounter or attackCounter == maxAttackCounter then
				ai.needAdvanced = true
			end
		end
		ai.needExperimental = false
		ai.needNukes = false
		if Metal.income > 50 and ai.haveAdvFactory  then
			if ai.combatCount >= attackCounter or couldAttack or ai.bomberhandler:GetCounter() == maxBomberCounter or attackCounter == maxAttackCounter then
			-- game:SendToConsole("checking for experimental...")
				if ai.enemyBasePosition and not ai.haveExpFactory then
					-- game:SendToConsole("has enemy base position")
					if ai.maphandler:MobilityNetworkSizeHere("bot", ai.enemyBasePosition) > ai.mobilityGridArea / 4 then
						ai.needExperimental = true
					else
						ai.needNukes = true
					end
				end
			end
		end
		if not ai.needNukes and Metal.income >= 35 and ai.haveAdvFactory then
			if ai.combatCount >= attackCounter or couldAttack or ai.bomberhandler:GetCounter() == maxBomberCounter or attackCounter == maxAttackCounter then
				ai.needNukes = true
			end
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
	CheckForDangers()
	return needAA
end

function IsShieldNeeded()
	CheckForDangers()
	return needShields
end

function IsTorpedoNeeded()
	CheckForDangers()
	return needTorpedo
end

function IsAntinukeNeeded()
	CheckForDangers()
	return needAntinuke
end

function IsNukeNeeded()
	CheckForDangers()
	return needNukes
end

function CheckNearWater(builder, range)
	-- this is special case, it means the unit will not be built anyway
	if unitName == DummyUnitName then
		return unitName
	end
	local pos = builder:GetPosition()
	if range == nil then range = AreaCheckRange end
	-- now check how many of the wanted unit is nearby

	EchoDebug(""..unitName.." wanted, with range limit of "..unitLimit..", with "..NumberOfUnits.." already there. The check is: "..tostring(AllowBuilding))
	if AllowBuilding then
		return unitName
	else
		return DummyUnitName
	end
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
		if Energy.reserves >= 0.9 * Energy.capacity and extraE > 0 then
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
		if Metal.reserves >= 0.9 * Metal.capacity and extraM > 0 then
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
		local mtype = unitTable[unitName].mtype
		local attackCounter = ai.attackhandler:GetCounter(mtype)
		return BuildWithLimitedNumber(unitName, attackCounter*3)
	else
		return DummyUnitName
	end
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
		return DummyUnitName
	else
		unitName = "armwar"
	end
	unitName = BuildSiegeIfNeeded(unitName)
	if unitName == DummyUnitName then
		unitName = BuildDefendIfNeeded(unitName)
	end
	return unitName
end

function Lvl1VehBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corlevlr"
		unitName = BuildSiegeIfNeeded(unitName)
		if unitName == DummyUnitName then
			unitName = BuildDefendIfNeeded(unitName)
		end
		return unitName
	else
		unitName = "armjanus"
		unitName = BuildSiegeIfNeeded(unitName)
		if unitName == DummyUnitName then
			unitName = BuildDefendIfNeeded("armstump")
		end
		return unitName
	end
end

function Lvl2VehBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corgol"
	else
		unitName = "armmanni"
	end
	return BuildSiegeIfNeeded(unitName)
end

function Lvl2BotBreakthrough(self)
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsumo"
	else
		unitName = "armfboy"
	end
	unitName = BuildSiegeIfNeeded(unitName)
	if unitName == DummyUnitName then
		unitName = BuildDefendIfNeeded(unitName)
	end
	return unitName
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
	unitName = BuildSiegeIfNeeded(unitName)
	if unitName == DummyUnitName then
		unitName = BuildDefendIfNeeded(unitName)
	end
	return unitName
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
	unitName = BuildSiegeIfNeeded(unitName)
	if unitName == DummyUnitName then
		unitName = BuildDefendIfNeeded(unitName)
	end
	return unitName
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
	elseif ai.raiderCount[mtype] < raidCounter then
		return DummyUnitName
	else
		return BuildWithLimitedNumber(unitName, attackCounter*3)
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
	if averageWind > 11 then
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

-- cound how many of the specified unit we own
function CountOwnUnits(tmpUnitName)
	-- don't count no-units
	if tmpUnitName == DummyUnitName then
		return 0
	end
	local ownUnits = game:GetFriendlies()
	local unitCount = 0
	local ownTeamID = game:GetTeamID()
	for _, u in pairs(ownUnits) do
		local un = u:Name()
		if un == tmpUnitName then
			local ut = u:Team()
			if ut == ownTeamID then
				unitCount = unitCount + 1
			end
		end
	end
	return unitCount
end

-- count how many of the unit the entire team owns
function CountFriendlyUnits(tmpUnitName)
	-- don't count no-units
	if tmpUnitName == DummyUnitName then
		return 0
	end
	local ownUnits = game:GetFriendlies()
	local unitCount = 0
	local ownTeamID = game:GetTeamID()
	for _, u in pairs(ownUnits) do
		local un = u:Name()
		if un == tmpUnitName then
			unitCount = unitCount + 1
		end
	end
	return unitCount
end


-- this function also checks for unit's team
-- so that allied factories don't prevent AI from making its own
function BuildWithLimitedNumber(tmpUnitName, minNumber)
	local ownUnits = game:GetFriendlies()
	local unitCount = 0
	local ownTeamID = game:GetTeamID()
	-- optimisation: don't check if it's already a null unit
	if tmpUnitName == DummyUnitName then
		return tmpUnitName
	end
	for _, u in pairs(ownUnits) do
		local un = u:Name()
		if un == tmpUnitName then
			local ut = u:Team()
			if ut == ownTeamID then
				unitCount = unitCount + 1
			end
		end
		if unitCount >= minNumber then
			break
		end
	end
	if unitCount >= minNumber then
		return DummyUnitName
	else
		return tmpUnitName
	end
end


-- build if no energy stall
local function MexEcon(unitName)
	if unitName == DummyUnitName then return DummyUnitName end
	return BuildWithNoEnergyStall(unitName)
end

-- build only if energy is low
local function EnergyPlantEcon(unitName)
	if unitName == DummyUnitName then return DummyUnitName end
	local res = game:GetResourceByName("Energy")
	if res.reserves < 0.25 * res.capacity or res.income < 50 then
		return unitName
	else
		return DummyUnitName
	end
end

-- build only if plenty of metal reserves and no energy stall
local function FactoryEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	if unitName == DummyUnitName then return DummyUnitName end
	local Energy = game:GetResourceByName("Energy")
	local Metal = game:GetResourceByName("Metal")
	EchoDebug(unitName)
	EchoDebug(unitTable[unitName])
	if Metal.reserves < unitTable[unitName].metalCost / 1.5 or Metal.income < unitTable[unitName].metalCost / 160 or Energy.income < 50  then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(unitName)
	end
end

-- build only if a bit of metal reserves and income proportional to cost and no energy stall
local function CombatEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	if unitName == DummyUnitName then return DummyUnitName end
	local res = game:GetResourceByName("Metal")
	if res.reserves < unitTable[unitName].metalCost / 10 or res.income < math.sqrt(unitTable[unitName].metalCost) * 1.25 - 10 then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(unitName)
	end
end

-- build only if some metal reserves and no energy stall
local function ConstructionEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	if unitName == DummyUnitName then return DummyUnitName end
	local res = game:GetResourceByName("Metal")
	if res.reserves < unitTable[unitName].metalCost / 4 then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(unitName)
	end
end

-- build only if a bit of metal reserves and income and energy extra proportional to cost and no energy stall
local function DefenseEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	local res = game:GetResourceByName("Metal")
	if res.reserves < unitTable[unitName].metalCost / 8 or res.income < math.sqrt(unitTable[unitName].metalCost) * 1.5 - 12 then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(BuildWithExtraEnergyIncome(unitName, unitTable[unitName].metalCost * 0.1))
	end
end

-- build only if some metal reserves and no energy stall
local function BuildingEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	if unitName == DummyUnitName then return DummyUnitName end
	local res = game:GetResourceByName("Metal")
	if res.reserves < unitTable[unitName].metalCost / 8 then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(unitName)
	end
end

-- build only if some metal reserves and no energy stall
local function OtherEcon(unitName)
	while type(unitName) == "function" do
		unitName = unitName(self)
	end
	if unitName == DummyUnitName then return DummyUnitName end
	local res = game:GetResourceByName("Metal")
	if res.reserves < unitTable[unitName].metalCost / 6 then
		return DummyUnitName
	else
		return BuildWithNoEnergyStall(unitName)
	end
end



function BuildWithMinimalMetalIncome(unitName, minNumber)
	local res = game:GetResourceByName("Metal")
	if res.income < minNumber then
		return DummyUnitName
	else
		return unitName
	end
end

-- build something only if we produce at least this much energy, and our e-storage is at least 1/4 full (so probably no estall)
function BuildWithMinimalEnergyIncome(unitName, minNumber)
	local res = game:GetResourceByName("Energy")
	if (res.income < minNumber) or (res.reserves < 0.25 * res.capacity) then
		return DummyUnitName
	else
		return unitName
	end
end

-- build something only if e-storage is at least 1/4 full (so probably no estall)
function BuildWithNoEnergyStall(unitName)
	local res = game:GetResourceByName("Energy")
	if res.reserves < 0.25 * res.capacity then
		return DummyUnitName
	else
		return unitName
	end
end

function BuildWithExtraEnergyIncome(unitName, minNumber)
	local res = game:GetResourceByName("Energy")
	if res.income - res.usage < minNumber then
		return DummyUnitName
	else
		return unitName
	end
end

function BuildWithExtraMetalIncome(unitName, minNumber)
	local res = game:GetResourceByName("Metal")
	EchoDebug("BuildWithExtraMetalIncome: income "..res.income..", usage "..res.usage..", threshold "..minNumber)
	if res.income - res.usage < minNumber then
		return DummyUnitName
	else
		return unitName
	end
end

function BuildWithNoExtraMetal(unitName)
	local res = game:GetResourceByName("Metal")
	if res.income - res.usage < 1 then
		return unitName
	else
		return DummyUnitName
	end
end

function CoreMetalMaker()
	-- check that we have energy surplus and not a metal surplus
	if ai.mySide == CORESideName then
		return BuildWithLimitedNumber(BuildWithExtraEnergyIncome(BuildWithNoExtraMetal("cormakr"), 75), 10)
	else
		return BuildWithLimitedNumber(BuildWithExtraEnergyIncome(BuildWithNoExtraMetal("armmakr"), 75), 10)
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

local function AdvFactory1(self)
	local botName
	local vehName
	local shpName
	local airName
	local whatToBuild = DummyUnitName
	local thisUnit = self.unit:Internal()
	
	if ai.mySide == CORESideName then
		botName = "coralab"
		vehName = "coravp"
		shpName = "corasy"
		airName = "coraap"
	else
		botName = "armalab"
		vehName = "armavp"
		shpName = "armasy"
		airName = "armaap"
	end

	local botType = game:GetTypeByName(botName)
	local vehType = game:GetTypeByName(vehName)
	local shpType = game:GetTypeByName(shpName)
	local airType = game:GetTypeByName(airName)

	if thisUnit:CanBuild(vehType) and BuildWithLimitedNumber(vehName, 1) == vehName then
		whatToBuild = vehName
	elseif thisUnit:CanBuild(botType) and BuildWithLimitedNumber(botName, 1) == botName then
		whatToBuild = botName
	elseif thisUnit:CanBuild(shpType) and BuildWithLimitedNumber(shpName, 1) == shpName then
		whatToBuild = shpName
	elseif thisUnit:CanBuild(airType) and BuildWithLimitedNumber(airName, 1) == airName then
		whatToBuild = airName
	end

	return whatToBuild
end

local function SecondaryFactory1(self)
	local botName
	local vehName
	local shpName
	local airName
	local ampName
	local hovName
	local whatToBuild = DummyUnitName
	local thisUnit = self.unit:Internal()
	if ai.mySide == CORESideName then
		botName = "coralab"
		vehName = "coravp"
		shpName = "corasy"
		airName = "coraap"
		ampName = "csubpen"
		hovName = "corhp"
	else
		botName = "armalab"
		vehName = "armavp"
		shpName = "armasy"
		airName = "armaap"
		ampName = "asubpen"
		hovName = "armhp"
	end

	local botType = game:GetTypeByName(botName)
	local vehType = game:GetTypeByName(vehName)
	local shpType = game:GetTypeByName(shpName)
	local airType = game:GetTypeByName(airName)
	local ampType = game:GetTypeByName(ampName)
	local hovType = game:GetTypeByName(hovName)

	local maptype = MapLandType()

	if thisUnit:CanBuild(ampType) and maptype == "amp" and BuildWithLimitedNumber(ampName, 1) == ampName then
		whatToBuild = ampName
	elseif thisUnit:CanBuild(hovType) and maptype == "hov" and BuildWithLimitedNumber(hovName, 1) == hovName then
		whatToBuild = hovName
	elseif thisUnit:CanBuild(vehType) and BuildWithLimitedNumber(vehName, 1) == vehName then
		whatToBuild = vehName
	elseif thisUnit:CanBuild(botType) and BuildWithLimitedNumber(botName, 1) == botName then
		whatToBuild = botName
	elseif thisUnit:CanBuild(shpType) and BuildWithLimitedNumber(shpName, 1) == shpName then
		whatToBuild = shpName
	elseif thisUnit:CanBuild(airType) and BuildWithLimitedNumber(airName, 1) == airName then
		whatToBuild = airName
	end

	return whatToBuild
end

local function BuildExperimentalFactory1(self)
	local expName
	if ai.mySide == CORESideName then
		expName = "corgant"
	else
		expName = "armshltx"
	end
	local expType = game:GetTypeByName(expName)
	local thisUnit = self.unit:Internal()
	if thisUnit:CanBuild(expType) then
		return BuildWithLimitedNumber(expName, 1)
	else
		return DummyUnitName
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
	return unitName
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

-- how many of our own unitName there are in a radius around a position
function CheckForOwnRadar(unitName, pos)
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

-- how many enemies are there in a radius around a position, also returns buildings and factories
function CountEnemiesInRadius(pos, radius, maxCount)
	local enemies = game:GetEnemies()
	local buildingCount = 0
	local factoryCount = 0
	local enemyCount = 0
	for _, e in pairs(enemies) do
		local epos = e:GetPosition()
		if distance(pos, epos) < radius then
			if unitTable[e:Name()].isBuilding then
				buildingCount = buildingCount + 1
				if unitTable[e:Name()].buildOptions ~= nil then
					factoryCount = factoryCount + 1
				end
			else
				enemyCount = enemyCount + 1
			end
			-- optimisation: if the limit is already exceeded, don't count further
			if enemyCount >= maxCount then
				break
			end
		end
	end
	return enemyCount, buildingCount, factoryCount
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

local function CheckDefenseLocalization(unitName, builder)
	local pos = builder:GetPosition()
	local size = 0
	if unitTable[unitName].groundRange > 0 then
		local vehsize = ai.maphandler:MobilityNetworkSizeHere("veh", pos)
		local botsize = ai.maphandler:MobilityNetworkSizeHere("bot", pos)
		size = math.max(vehsize, botsize)
	elseif unitTable[unitName].airRange > 0 then
		return unitName
	elseif  unitTable[unitName].submergedRange > 0 then
		size = ai.maphandler:MobilityNetworkSizeHere("sub", pos)
	end
	EchoDebug("network size here" .. size .. " minimum " .. minDefenseNetworkSize)
	if size < minDefenseNetworkSize then
		return DummyUnitName
	else
		return unitName
	end
end

local function CheckAreaLimitDefense(unitName, builder)
	EchoDebug(unitName)
	unitName = CheckDefenseLocalization(unitName, builder)
	if unitName == DummyUnitName then return DummyUnitName end
	EchoDebug("area checking " .. unitName .. " for defense")
	local range = math.max(unitTable[unitName].groundRange, unitTable[unitName].airRange, unitTable[unitName].submergedRange)
	if range == 0 then
		EchoDebug(unitName .. " is not a weapon, cannot CheckAreaLimitDefense")
		return DummyUnitName
	else
		range = math.floor(range * 0.9)
		return CheckAreaLimit(unitName, builder, 1, range)
	end
end

local function CheckAreaLimitRadar(unitName, builder)
	if unitName == DummyUnitName then return DummyUnitName end
	local rad = unitTable[unitName].radarRadius
	if rad == 0 then
		EchoDebug(unitName .. " is not radar, cannot CheckAreaLimitRadar")
		return DummyUnitName
	else
		-- look for radar ranges and don't build this radar if it's too close to another
		local pos = builder:GetPosition()
		local ownUnits = game:GetFriendlies()
		for _, u in pairs(ownUnits) do
			local urad = unitTable[u:Name()].radarRadius
			if urad > 0 and u:Name() ~= "armcom" and u:Name() ~= "corcom" then
				local upos = u:GetPosition()
				if distance(pos, upos) < (urad + rad) * 0.67 then
					return DummyUnitName
				end
			end
		end
		return unitName
	end
end

local function CheckAreaLimitSonar(unitName, builder)
	if unitName == DummyUnitName then return DummyUnitName end
	local rad = unitTable[unitName].sonarRadius
	if rad == 0 then
		EchoDebug(unitName .. " is not sonar, cannot CheckAreaLimitSonar")
		return DummyUnitName
	else
		-- look for radar ranges and don't build this radar if it's too close to another
		local pos = builder:GetPosition()
		local ownUnits = game:GetFriendlies()
		for _, u in pairs(ownUnits) do
			local urad = unitTable[u:Name()].sonarRadius
			if urad > 0 then
				local upos = u:GetPosition()
				if distance(pos, upos) < (urad + rad) * 0.67 then
					return DummyUnitName
				end
			end
		end
		return unitName
	end
end

-- build if in weapon range of an enemy factory, 10 enemy buildings, or 25 enemies
local function CheckBombard(unitName, builder)
	local pos = builder:GetPosition()
	if ai.targethandler:IsBombardPosition(pos, unitName) then
		return unitName
	else
		return DummyUnitName
	end
end

local function BuildWithNearbyFactory(unitName, builder)
	-- this is special case, it means the unit will not be built anyway
	if unitName == DummyUnitName then
		return unitName
	end
	local pos = builder:GetPosition()
	local ownUnits = game:GetFriendlies()
	local unitCount = 0
	for _, u in pairs(ownUnits) do
		local ut = unitTable[u:Name()]
		if ut.buildOptions ~= nil and ut.isBuilding then
			local upos = u:GetPosition()
			if distance(pos, upos) < 390 then
				return unitName
			end
		end
	end
	return DummyUnitName
end

function BuildShield(self)
	if self.unit == nil then
		return DummyUnitName
	end
	if IsShieldNeeded() then
		local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corgate"
		else
			unitName = "armgate"
		end
		return DummyUnitName
	end
	return DummyUnitName
end

function BuildAntinuke(self)
	if self.unit == nil then
		return DummyUnitName
	end
	if IsAntinukeNeeded() then
		local unitName = ""
		if ai.mySide == CORESideName then
			unitName = "corfmd"
		else
			unitName = "armamd"
		end
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
	return DummyUnitName
end

function BuildNuke(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsilo"
	else
		unitName = "armsilo"
	end
	local unit = self.unit:Internal()
	return CheckBombard(unitName, unit)
end

function BuildNukeIfNeeded(self)
	if self.unit == nil then
		return DummyUnitName
	end
	if IsNukeNeeded() then
		return BuildNuke(self)
	end
end

local function AreaLimit_Lvl1Plasma(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corpun"
	else
		unitName = "armguard"
	end
	local unit = self.unit:Internal()
	return CheckBombard(unitName, unit)
end

local function AreaLimit_Lvl2Plasma(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cortoast"
	else
		unitName = "armamb"
	end
	local unit = self.unit:Internal()
	return CheckBombard(unitName, unit)
end

local function AreaLimit_HeavyPlasma(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corint"
	else
		unitName = "armbrtha"
	end
	local unit = self.unit:Internal()
	return CheckBombard(unitName, unit)
end

local function AreaLimit_LLT(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_SpecialLT(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_SpecialLTOnly(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_FloatHLT(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_HLT(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_Lvl2PopUp(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_Tachyon(self)
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
	return CheckAreaLimitDefense(unitName, unit)
end

local function AreaLimit_DepthCharge(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cordl"
	else
		unitName = "armdl"
	end
	unitName = BuildTorpedoIfNeeded(unitName)
	if unitName ~= DummyUnitName then
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	else
		return DummyUnitName
	end
end


local function AreaLimit_LightTorpedo(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "cortl"
	else
		unitName = "armtl"
	end
	unitName = BuildTorpedoIfNeeded(unitName)
	if unitName ~= DummyUnitName then
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	else
		return DummyUnitName
	end
end

local function AreaLimit_HeavyTorpedo(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "coratl"
	else
		unitName = "armatl"
	end
	unitName = BuildTorpedoIfNeeded(unitName)
	if unitName ~= DummyUnitName then
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	else
		return DummyUnitName
	end
end


-- build AA in area only if there's not enough of it there already
local function AreaLimit_LightAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corrl")
	else
		unitName = BuildAAIfNeeded("armrl")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_FloatLightAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corfrt")
	else
		unitName = BuildAAIfNeeded("armfrt")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_MediumAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("madsam")
	else
		unitName = BuildAAIfNeeded("packo")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_HeavyishAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corerad")
	else
		unitName = BuildAAIfNeeded("armcir")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_HeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corflak")
	else
		unitName = BuildAAIfNeeded("armflak")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_FloatHeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("corfflak")
	else
		unitName = BuildAAIfNeeded("armfflak")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_ExtraHeavyAA(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = BuildAAIfNeeded("screamer")
	else
		unitName = BuildAAIfNeeded("mercury")
	end
	-- our unit type and coords
	if unitName == DummyUnitName then
		return unitName
	else
		local unit = self.unit:Internal()
		return CheckAreaLimitDefense(unitName, unit)
	end
end

local function AreaLimit_Sonar(self)
	if self.unit == nil then
		return DummyUnitName
	end
	if not IsTorpedoNeeded() then return DummyUnitName end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corsonar"
	else
		unitName = "armsonar"
	end
	local unit = self.unit:Internal()
	return CheckAreaLimitSonar(unitName, unit)
end

local function AreaLimit_AdvancedSonar(self)
	if self.unit == nil then
		return DummyUnitName
	end
	if not IsTorpedoNeeded() then return DummyUnitName end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corason"
	else
		unitName = "armason"
	end
	local unit = self.unit:Internal()
	return CheckAreaLimitSonar(unitName, unit)
end


local function AreaLimit_Radar(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corrad"
	else
		unitName = "armrad"
	end
	unitName = BuildWithLimitedNumber(unitName, 1)
	if unitName == DummyUnitName then
		local unit = self.unit:Internal()
		return CheckAreaLimitRadar(unitName, unit)
	else
		return unitName
	end
end

local function AreaLimit_FloatRadar(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corfrad"
	else
		unitName = "armfrad"
	end
	unitName = BuildWithLimitedNumber(unitName, 1)
	if unitName == DummyUnitName then
		local unit = self.unit:Internal()
		return CheckAreaLimitRadar(unitName, unit)
	else
		return unitName
	end
end

local function AreaLimit_AdvancedRadar(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = ""
	if ai.mySide == CORESideName then
		unitName = "corarad"
	else
		unitName = "armarad"
	end
	local unit = self.unit:Internal()
	return CheckAreaLimitRadar(unitName, unit)
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

local function NanoTurretNearFactory(self)
	if self.unit == nil then
		return DummyUnitName
	end
	local unitName = NanoTurret()

	local unit = self.unit:Internal()
	-- check that we have at least a bit of free metal to use on expansion, and build next to factory
	return BuildWithNearbyFactory(unitName, unit)
end

local function AirRepairPadIfNeeded()
	local tmpUnitName = DummyUnitName

	-- only make air pads if the team has at least 1 air fac
	if CountFriendlyUnits("corap") > 0 or CountFriendlyUnits("armap") > 0 or CountFriendlyUnits("coraap") > 0 or CountFriendlyUnits("armaap") > 0 then
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

local function Lvl1AirPlant()
	if ai.mySide == CORESideName then
		return "corap"
	else
		return"armap"
	end
end

local function Lvl1BotLab()
	if ai.mySide == CORESideName then
		return "corlab"
	else
		return"armlab"
	end
end

local function Lvl1VehPlant()
	if ai.mySide == CORESideName then
		return "corvp"
	else
		return "armvp"
	end
end

local function Lvl1ShipYard()
	if ai.mySide == CORESideName then
		return "corsy"
	else
		return "armsy"
	end
end

local function AmphibiousComplex()
	if ai.mySide == CORESideName then
		return "csubpen"
	else
		return "asubpen"
	end
end

local function HoverPlatformIfNeeded()
	local maptype = MapLandType()
	if maptype == "hov" or ai.mobRating["hov"] > ai.mobRating["veh"] or ai.mobRating["hov"] > ai.mobRating["bot"] or ai.mobRating["hov"] > ai.mobRating["amp"] then
		if ai.mySide == CORESideName then
			return "corhp"
		else
			return "armhp"
		end
	else
		return DummyUnitName
	end
end

local function FloatHoverPlatformIfNeeded()
	local maptype = MapLandType()
	if maptype == "hov" or ai.mobRating["hov"] > ai.mobRating["veh"] or ai.mobRating["hov"] > ai.mobRating["bot"] or ai.mobRating["hov"] > ai.mobRating["amp"] then
		if ai.mySide == CORESideName then
			return "corfhp"
		else
			return "armfhp"
		end
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

local function CommanderFactory1()
	local r = 2
	local maptype = MapLandType()
	-- if it's a bot map, do not build vehicle factory
	if maptype == "air" then
		-- build only aircraft plant and then maybe shipyard
		r = 0
		if CheckForOwnUnit(Lvl1AirPlant()) then
			if ai.mobRating["veh"] > mobilityRatingFloor or ai.mobRating["hov"] > mobilityRatingFloor or ai.mobRating["amp"] > mobilityRatingFloor then
				r = 2
			elseif ai.mobRating["bot"] > mobilityRatingFloor then
				r = 1
			elseif ai.mobRating["shp"] > mobilityRatingFloor or ai.mobRating["sub"] > mobilityRatingFloor then
				r = 3
			end
		end
	elseif maptype == "bot" then
		-- build lab first, then maybe aircraft plant or shipyard
		r = 1
		if CheckForOwnUnit(Lvl1BotLab()) then
			if ai.mobRating["veh"] > mobilityRatingFloor or ai.mobRating["hov"] > mobilityRatingFloor or ai.mobRating["amp"] > mobilityRatingFloor then
				r = 2
			elseif ai.mobRating["shp"] > mobilityRatingFloor or ai.mobRating["sub"] > mobilityRatingFloor then
				r = 3
			else
				r = 0
			end
		end
	elseif maptype == "veh" or maptype == "amp" or maptype == "hov" then
		-- build vehicle plant first, then maybe lab or aircraft plant
		r = 2
		if CheckForOwnUnit(Lvl1VehPlant()) then
			if ai.mobRating["bot"] > mobilityRatingFloor then
				r = 1
			elseif ai.mobRating["shp"] > mobilityRatingFloor or ai.mobRating["sub"] > mobilityRatingFloor then
				r = 3
			else
				r = 0
			end
		end
	elseif maptype == "shp" or maptype == "sub" then
		-- build a shipyard
		r = 3
		if CheckForOwnUnit(Lvl1ShipYard()) then
			if ai.mobRating["veh"] > mobilityRatingFloor or ai.mobRating["hov"] > mobilityRatingFloor or ai.mobRating["amp"] > mobilityRatingFloor then
				r = 2
			elseif ai.mobRating["bot"] > mobilityRatingFloor then
				r = 1
			else
				r = 0
			end
		end
	end
	if r == 0 then
		ret = Lvl1AirPlant()
	elseif r == 1 then
		ret = Lvl1BotLab()
	elseif r == 2 then
		ret = Lvl1VehPlant()
	elseif r == 3 then
		ret = Lvl1ShipYard()
	end
	return BuildWithLimitedNumber(ret, 1)
end

local function BuildAppropriateFactory(self)
	local builder = self.unit:Internal()
	EchoDebug("checking control for " .. builder:Name())
	CheckForMapControl()
	EchoDebug("building appropriate factory..")
	local factories, advanced, experimental = ai.maphandler:WhatFactories(builder)
	if experimental ~= nil and ai.needExperimental then
		local position = builder:GetPosition()
		EchoDebug(tostring(ai.enemyBasePosition))
		if ai.enemyBasePosition then
			if ai.maphandler:MobilityNetworkHere("bot", position) == ai.maphandler:MobilityNetworkHere("bot", ai.enemyBasePosition) then
				return BuildWithLimitedNumber(experimental, 1)
			else
				return BuildNuke(self)
			end
		end
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


local anyCommander = {
	CheckMySideIfNeeded,
	BuildAppropriateFactory,
	WindSolar,
	TidalIfTidal,
	AreaLimit_LLT,
	AreaLimit_Radar,
	AreaLimit_Sonar,
	AreaLimit_LightAA,
	AreaLimit_DepthCharge,
	DoSomethingForTheEconomy,
	BuildMex,
}

local anyConUnit = {
	BuildAppropriateFactory,
	NanoTurret,
	BuildGeo,
	BuildMex,
	AreaLimit_SpecialLT,
	AreaLimit_MediumAA,
	AreaLimit_Radar,
	WindSolar,
	SolarAdv,
	AreaLimit_HLT,
	AreaLimit_Lvl1Plasma,
	DoSomethingForTheEconomy,
	AreaLimit_HeavyishAA,
}

local anyConAmphibious = {
	BuildGeo,
	AreaLimit_SpecialLT,
	AreaLimit_MediumAA,
	AreaLimit_Radar,
	WindSolar,
	SolarAdv,
	FactoryOrNano,
	AreaLimit_HLT,
	AreaLimit_Lvl1Plasma,
	DoSomethingForTheEconomy,
	AreaLimit_HeavyishAA,
	BuildMex,
	AreaLimit_LightTorpedo,
	AreaLimit_FloatLightAA,
	AreaLimit_Sonar,
	AreaLimit_LightTorpedo,
	AreaLimit_FloatRadar,
	TidalIfTidal,
	AreaLimit_FloatHLT,
	DoSomethingForTheEconomy,
	AreaLimit_DepthCharge,
}

local anyConShip = {
	BuildUWMex,
	AreaLimit_FloatLightAA,
	AreaLimit_Sonar,
	AreaLimit_LightTorpedo,
	AreaLimit_FloatRadar,
	TidalIfTidal,
	BuildAppropriateFactory,
	AreaLimit_FloatHLT,
	DoSomethingForTheEconomy,
	AreaLimit_DepthCharge,
}

local anyAdvConUnit = {
	BuildMohoGeo,
	BuildMohoMex,
	AreaLimit_Lvl2PopUp,
	AreaLimit_HeavyAA,
	BuildAntinuke,
	AreaLimit_Lvl2Plasma,
	AreaLimit_Tachyon,
	AreaLimit_HeavyPlasma,
	BuildFusion,
	AreaLimit_AdvancedRadar,
	BuildAppropriateFactory,
	BuildNukeIfNeeded,
	AreaLimit_ExtraHeavyAA,
}

local anyAdvConSub = {
	BuildUWMohoMex,
	AreaLimit_FloatHeavyAA,
	BuildUWFusion,
	AreaLimit_AdvancedSonar,
	AreaLimit_HeavyTorpedo,
}

local anyNavalEngineer = {
	AreaLimit_FloatHLT,
	AreaLimit_FloatLightAA,
	BuildAppropriateFactory,
	Lvl1ShipBattle,
	AreaLimit_FloatRadar,
	TidalIfTidal,
	BuildUWMex,
	AreaLimit_Sonar,
	Lvl1ShipRaider,
	Conship,
	ScoutShip,
	AreaLimit_LightTorpedo,
}

local anyCombatEngineer = {
	BuildAppropriateFactory,
	NanoTurret,
	Solar,
	AreaLimit_MediumAA,
	AreaLimit_AdvancedRadar,
	AreaLimit_Lvl2PopUp,
	AreaLimit_HeavyAA,
	AreaLimit_SpecialLTOnly,
	AreaLimit_Lvl2Plasma,
	ConCoreBotArmVehicle,
	Lvl2BotCorRaiderArmBattle,
	Lvl1AABot,
	ConShip,
	Lvl1ShipDestroyerOnly,
	BuildMex,
}

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