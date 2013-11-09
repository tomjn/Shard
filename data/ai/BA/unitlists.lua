require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("unitLists: " .. inStr)
	end
end

function RandomAway(pos, dist)
	local xdelta = math.random(0, dist*2) - dist
	local zmult = math.random(0,1) == 1 and 1 or -1
	local zdelta = (dist - math.abs(xdelta)) * zmult
	pos.x = pos.x + xdelta
	pos.z = pos.z + zdelta
	if pos.x < 1 then
		pos.x = 1
	elseif pos.x > ai.maxElmosX - 1 then
		pos.x = ai.maxElmosX - 1
	end
	if pos.z < 1 then
		pos.z = 1
	elseif pos.z > ai.maxElmosZ - 1 then
		pos.z = ai.maxElmosZ - 1
	end
	return pos
end

sqrt = math.sqrt

function distance(pos1,pos2)
	local xd = pos1.x-pos2.x
	local yd = pos1.z-pos2.z
	local dist = sqrt(xd*xd + yd*yd)
	return dist
end

function quickdistance(pos1,pos2)
	local xd = math.abs(pos1.x-pos2.x)
	local yd = math.abs(pos1.z-pos2.z)
	local dist = xd + yd
	return dist
end

function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function UnitValue(unitName)
	local utable = unitTable[unitName]
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

function UnitThreat(unitName, groundAirSubmerged)
	local utable = unitTable[unitName]
	local threat = utable.metalCost
	if groundAirSubmerged == "ground" then
		threat = threat + utable.groundRange
	elseif groundAirSubmerged == "air" then
		threat = threat + utable.airRange
	elseif groundAirSubmerged == "submerged" then
		threat = threat + utable.submergedRange
	elseif groundAirSubmerged == "all" then
		threat = threat + utable.submergedRange + utable.airRange + utable.groundRange
	end
	return threat
end

factoryMobilities = {
	corap = {"air"},
	armap = {"air"},
	corlab = {"bot"},
	armlab = {"bot"},
	corvp = {"veh"},
	armvp = {"veh"},
	coralab = {"bot"},
	coravp = {"veh"},
	corhp = {"hov"},
	armhp = {"hov"},
	corfhp = {"hov"},
	armfhp = {"hov"},
	armalab = {"bot"},
	armavp = {"veh"},
	coraap = {"air"},
	armaap = {"air"},
	corsy = {"shp", "sub"},
	armsy = {"shp", "sub"},
	corasy = {"shp", "sub"},
	armasy = {"shp", "sub"},
	csubpen = {"sub", "amp"},
	csubpen = {"sub", "amp"},
	corgant = {"bot"},
	armshltx = {"bot"},
}

local function BuilderFactoriesByMobility()
	local builderFactByMob = {}
	for name, utable in pairs(unitTable) do
		if utable.factoriesCanBuild ~= nil then
			local factByMob = {}
			for i, fname in pairs(utable.factoriesCanBuild) do
				EchoDebug(fname)
				local mtypes = factoryMobilities[fname]
				if mtypes ~= nil then
					for mi, mtype in pairs(mtypes) do
						if factByMob[mtype] == nil then
							factByMob[mtype] = fname
						else
							if unitTable[fname].techLevel > unitTable[factByMob[mtype]].techLevel then
								factByMob[mtype] = fname
							end
						end
					end
				end
			end
			builderFactByMob[name] = factByMob
		end
	end
	return builderFactByMob
end

builderFactByMob = BuilderFactoriesByMobility()

-- these big energy plants will be shielded in addition to factories
bigEnergyPlant = {
	cmgeo = 1,
	amgeo = 1,
	corfus = 1,
	armfus = 1,
	cafus = 1,
	aafus = 1,
}

-- geothermal plants
geothermalPlant = {
	corgeo = 1,
	armgeo = 1,
	cmgeo = 1,
	amgeo = 1,
	corbhmth = 1,
	armgmm = 1,
}

-- what mexes upgrade to what
mexUpgrade = {
	cormex = "cormoho",
	armmex = "armmoho",
	coruwmex = "coruwmme",
	armuwmex = "armuwmme",
}

-- these will be abandoned faster
hyperWatchdog = {
	armmex = 1,
	cormex = 1,
	armgeo = 1,
	corgeo = 1,
}

-- things we really need to construct other than factories
-- value is max number of assistants to get if available (0 is all available)
helpList = {
	corfus = 0,
	armfus = 0,
	coruwfus = 0,
	armuwfus = 0,
	aafus = 0,
	cafus = 0,
	corgeo = 2,
	armgeo = 2,
	cmgeo = 0,
	amgeo = 0,
	cormoho = 2,
	armmoho = 2,
	coruwmme = 2,
	armuwmme = 2,
}

-- things to defend other than factories and con units
-- value is priority
defendList = {
	corfus = 2,
	armfus = 2,
	aafus = 3,
	cafus = 3,
	cmgeo = 2,
	amgeo = 2,
}

-- factories that can build advanced construction units (i.e. moho mines)
advFactories = {
	coravp = 1,
	coralab = 1,
	corasy = 1,
	coraap = 1,
	armavp = 1,
	armalab = 1,
	armasy = 1,
	armaap = 1,
}

-- experimental factories
expFactories = {
	corgant = 1,
	armshltx = 1,
}

-- for milling about next to con units and factories only
defenderList = {
	"armaak",
	"corcrash",
	"armjeth",
	"corsent",
	"armyork",
	"corah",
	"armaas",
	"armah",
	"corarch",
	"armaser",
	"armjam",
	"armsjam",
	"coreter",
	"corsjam",
	"corspec",
	"armfig",
	"armhawk",
	"corveng",
	"corvamp",
}

attackerlist = {
	"armsam",
	"corwolv",
	"tawf013",
	"armjanus",
	"corlvlr",
	"corthud",
	"armham",
	"corraid",
	"armstump",
	"correap",
	"armbull",
	"corstorm",
	"armrock",
	"cormart",
	"armmart",
	"cormort",
	"armwar",
	"armsnipe",
	"armzeus",
	"corlevlr",
	"corsumo",
	"corcan",
	"corhrk",
	"corgol",
	"corvroc",
	"cormh",
	"armmanni",
	"armmerl",
	"armfido",
	"armsptk",
	"armmh",
	"corwolv",
	"cormist",
	"coresupp",
	"decade",
	"corroy",
	"armroy",
	"armfboy",
	"armraz",
	"armshock",
	"armbanth",
	"shiva",
	"armraven",
	"corkarg",
	"gorg",
	"corkrog",
	"corcrw",
	-- hover
	"corsnap",
	"armanac",
}


scoutList = {
	"corfink",
	"armpeep",
	"corfav",
	"armfav",
	"armflea",
	"corawac",
	"armawac",
	"corpt",
	"armpt",
}

commanderList = {
	armcom = 1,
	corcom = 1,
}

nanoTurretList = {
	cornanotc = 1,
	armnanotc = 1,
}

reclaimerList = {
	cornecro = 1,
	armrectr = 1,
	correcl = 1,
	armrecl = 1,
}

-- advanced construction units
advConList = {
	corack = 1,
	armack = 1,
	coracv = 1,
	armacv = 1,
	coraca = 1,
	armaca = 1,
}

-- these will be set to Hold Position
holdPositionList = {
	corthud = 1,
	armham = 1,
	corgol = 1,
	cormart = 1,
	armmart = 1,
	cormort = 1,
	corcrash = 1,
	armjeth = 1,
	armsnipe = 1,
	corlevlr = 1,
	corsent = 1,
	armyork = 1,
	corhrk = 1,
	cormh = 1,
	corah = 1,
	armmanni = 1,
	armmerl = 1,
	armfido = 1,
	corroy = 1,
	armroy = 1,
	armshock = 1,
	armfboy = 1,
	shiva = 1,
	armraven = 1,
	gorg = 1,
}

-- these will be set to Roam
roamList = {
	corak = 1,
	armpw = 1,
	armfast = 1,
	corpyro = 1,
	corpt = 1,
	armpt = 1,
	corsub = 1,
	armsub = 1,
	marauder = 1,
}

-- these will not be interrupted by watchdog checks
dontInterruptList = {
	"corack",
	"corfus",
	"coralab",
	"coravp",
	"corgeo",
	"corfmd",
	"armack",
	"armfus",
	"armalab",
	"armavp",
	"armgeo",
	"armamd",
	"corgant",
	"armshltx",
}

-- if any of these is found among enemy units, AA units and fighters will be built
airFacList = {
	"armap",
	"corap",
	"armaap",
	"coraap",
	"armplat",
	"corplat",
}

-- if any of these is found among enemy units, torpedo launchers and sonar will be built
subFacList = {
	"corsy",
	"armsy",
	"corasy",
	"armasy",
	"csubpen",
	"asubpen",
}

-- if any of these is found among enemy units, plasma shields will be built
bigPlasmaList = {
	"corint",
	"armbrtha",
}

-- if any of these is found among enemy units, antinukes will be built
nukeList = {
	"armsilo",
	"corsilo",
	"armemp",
	"cortron",
}	

-- these units will be used to raid weakly defended spots
raiderList = {
	"armfast",
	"corgator",
	"armflash",
	"corpyro",
	"armlatnk",
	"armpw",
	"corak",
	"marauder",
	-- amphibious
	"corgarp",
	"armpincer",
	-- hover
	"corsh",
	"armsh",
	-- air gunships
	"armbrawl",
	"armkam",
	"armsaber",
	"blade",
	"bladew",
	"corape",
	"corcut",
	-- subs
	"corsub",
	"armsub",
	"armsubk",
	"corsubk",
}

raiderDisarms = {
	bladew = 1,
}

-- these are placed using the alternate build location function
-- tends to find locations when standard one fails
unitsForNewPlacing = {
	corsolar = 6,
	corestor = 6,
	corlab = 10,
	coralab = 10,
	corvp = 10,
	corhp = 10,
	cormakr = 20,
	corfus = 20,
	armsolar = 6,
	armestor = 6,
	armlab = 10,
	armvp = 10,
	armavp = 10,
	armhp = 10,
	armmakr = 20,
	armfus = 20,
	corgeo = 20,
	armgeo = 20,
	cortide = 5, -- higher than 1 because otherwise tidals build inside shipyards
	armtide = 5,
	corfmd = 1,
	armamd = 1,
}

-- these will be placed closer together if first placement attempt fails
unitsForNewPlacingLowOnSpace = {
	corfus = 8,
	armfus = 8,
	coralab = 8,
	armavp = 8,
}

-- these will NOT cause alternative build spots to be evalueated
dontTryAlternativePoints = {
	cortide = 1,
	armtide = 1,
}

-- these will be ignored when looking for an attack target
unitsToIgnoreAsAttackTarget = {
	-- no sense chasing after planes
	corshad = 1,
	corfink = 1,
	corveng = 1,
	cortitan = 1,
	corhurc = 1,
	corca = 1,
	corvamp = 1,
	corawac = 1,
	corhunt = 1,
	armpeep = 1,
	armfig = 1,
	armthund = 1,
	armatlas = 1,
	armlance = 1,
	armpnix = 1,
	armca = 1,
	armhawk = 1,
	blade = 1,
	armawac = 1,
	armsehak = 1,
}

-- units to consider as targets for air (bomber) attacks
-- values are priority. Negative values decrease target weight (AA units in the same sector)
bomberAttackTargets =
{
	-- fusions = big BOOM
	corfus = 150,
	armfus = 150,
	-- WMD silos have lower priority, won't do much without resources
	armsilo = 60,
	corsilo = 60,
	armemp = 55,
	cortron = 55,
	-- moho mines
	cormoho = 50,
	armmoho = 50,
	-- factories
	coralab = 40,
	armalab = 40,
	coravp = 40,
	armavp = 40,
	coraap = 45,	-- those two produce stealth fighters
	armaap = 45,
	corasy = 40,
	armasy = 40,
	armap = 40,
	corap = 40,
	corsy = 35,
	armsy = 35,
	corlab = 35,
	armlab = 35,
	corvp = 35,
	armvp = 35,
	corap = 35,
	armap = 35,
	corhp = 35,
	armhp = 35,
	-- commanders = game end, but quite hard to kill
	corcom = 30,
	armcom = 30,
	-- mexes
	cormex = 5,
	armmex = 5,
	corfmex = 5,
	armfmex = 5,
	-- now the dangerous stuff
	corflak = -40,
	armflak = -40,
	cortflak = -40,
	armtflak = -40,
	-- flak vehs are a bit less powerful than turrets
	corsent = -32,
	armyork = -32,
	-- fighters and stealth fighters are really nasty
	armfig = -60,
	corveng = -60,
	armhawk = -80,
	corvamp = -80,
}

-- units in this list are bombers
bomberList =
{
	corshad = 1,
	armthund = 1,
	corhurc = 2,
	armpnix = 2,
	armcybr = 3,
}

-- minimum, maximum, starting point units required to attack, bomb
minAttackCounter = 5
maxAttackCounter = 20
baseAttackCounter = 10
minBomberCounter = 1
maxBomberCounter = 20
baseBomberCounter = 2

-- raid counter works backwards: it determines the number of raiders to build
-- if it reaches minRaidCounter, none are built
minRaidCounter = 1
maxRaidCounter = 6
baseRaidCounter = 4

-- how many mobile con units of one type is allowed
ConUnitPerTypeLimit = 4 --max(map:SpotCount() / 10, 2)
ConUnitAdvPerTypeLimit = 4

-- Taskqueuebehaviour was modified to skip this name
DummyUnitName = "skipthisorder"

-- this unit is used to check for underwater metal spots
UWMetalSpotCheckUnit = "coruwmex"

mobUnitName = {}
mobUnitName["veh"] = "armflash"
mobUnitName["bot"] = "corck"
mobUnitName["amp"] = "cormuskrat"
mobUnitName["hov"] = "corsh"
mobUnitName["shp"] = "corcs"
mobUnitName["sub"] = "coracsub"

-- this unit is used to check for hoverable water
WaterSurfaceUnitName = "armfdrag"

-- side names
CORESideName = "core"
ARMSideName = "arm"