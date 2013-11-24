require "unittable"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("unitLists: " .. inStr)
	end
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
	asubpen = {"sub", "amp"},
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

factoryExitSides = {
	corap = 0,
	armap = 0,
	corlab = 2,
	armlab = 2,
	corvp = 1,
	armvp = 1,
	coralab = 3,
	coravp = 1,
	corhp = 4,
	armhp = 4,
	corfhp = 4,
	armfhp = 4,
	armalab = 2,
	armavp = 2,
	coraap = 0,
	armaap = 0,
	corsy = 4,
	armsy = 4,
	corasy = 4,
	armasy = 4,
	csubpen = 4,
	asubpen = 4,
	corgant = 1,
	armshltx = 1,
}

littlePlasmaList = {
	corpun = 1,
	armguard = 1,
	cortoast = 1,
	armamb = 1,
	corbhmth = 1,
}

-- these big energy plants will be shielded in addition to factories
bigEnergyList = {
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

-- things to defend with defense towers other than factories
-- value is priority
turtleList = {
	aafus = 8,
	cafus = 8,
	corfus = 5,
	armfus = 5,
	cmgeo = 4,
	amgeo = 4,
	corgeo = 3,
	armgeo = 3,
	cormoho = 2,
	armmoho = 2,
	cormex = 1,
	armmex = 1,
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

-- sturdy, cheap units to be built in larger numbers than siege units
battleList = {
	corraid = 1,
	armstump = 1,
	corthud = 1,
	armham = 1,
	corstorm = 1,
	armrock = 1,
	coresupp = 1,
	decade = 1,
	corroy = 1,
	armroy = 1,
	corsnap = 1,
	armanac = 1,
	corseal = 1,
	armcroc = 1,
	correap = 2,
	armbull = 2,
	corcan = 2,
	armzeus = 2,
	corcrus = 2,
	armcrus = 2,
	corkarg = 3,
	armraz = 3,
}

-- sturdier units to use when battle units get killed
breakthroughList = {
	corlevlr = 1,
	armwar = 1,
	corgol = 2,
	corsumo = 2,
	armfboy = 2,
	corparrow = 2,
	nsaclash = 2,
	corbats = 2,
	armbats = 2,
	corkrog = 3,
	gorg = 3,
	armbanth = 3,
	corblackhy = 3,
	aseadragon = 3,
	corcrw = 3,
	armcybr = 3,
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
	"armfboy",
	"corcrw",
	-- experimentals
	"armraz",
	"armshock",
	"armbanth",
	"shiva",
	"armraven",
	"corkarg",
	"gorg",
	"corkrog",
	-- ships
	"coresupp",
	"decade",
	"corroy",
	"armroy",
	"corcrus",
	"armcrus",
	"corblackhy",
	"aseadragon",
	-- hover
	"corsnap",
	"armanac",
	"nsaclash",
	-- amphib
	"corseal",
	"armcroc",
	"corparrow",
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

antinukeList = {
	corfmd = 1,
	armamd = 1,
	corcarry = 1,
	armcarry = 1,
	cormabm = 1,
	armscab = 1,
}

shieldList = {
	corgate = 1,
	armgate = 1,
}

commanderList = {
	armcom = 1,
	corcom = 1,
}

nanoTurretList = {
	cornanotc = 1,
	armnanotc = 1,
}

-- cheap construction units that can be built in large numbers
assistList = {
	armfark = 1,
	corfast = 1,
	consul = 1,
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

groundFacList = {
	corvp = 1,
	armvp = 1,
	coravp = 1,
	armavp = 1,
	corlab = 1,
	armlab = 1,
	coralab = 1,
	armalab = 1,
	corhp = 1,
	armhp = 1,
	corfhp = 1,
	armfhp = 1,
	csubpen = 1,
	asubpen = 1,
	corgant = 1,
	armshltx = 1,
	corfast = 1,
	consul = 1,
	armfark = 1,
}

-- if any of these is found among enemy units, AA units and fighters will be built
airFacList = {
	corap = 1,
	armap = 1,
	coraap = 1,
	armaap = 1,
	corplat = 1,
	armplat = 1,
}

-- if any of these is found among enemy units, torpedo launchers and sonar will be built
subFacList = {
	corsy = 1,
	carmsy = 1,
	corasy = 1,
	armasy = 1,
	csubpen = 1,
	asubpen = 1,
}

-- if any of these is found among enemy units, plasma shields will be built
bigPlasmaList = {
	corint = 1,
	armbrtha = 1,
}

-- if any of these is found among enemy units, antinukes will be built
-- also used to assign nuke behaviour to own units
-- values are how many frames it takes to stockpile
nukeList = {
	armsilo = 3600,
	corsilo = 5400,
	armemp = 2700,
	cortron = 2250,
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
breakthroughAttackCounter = 11 -- build heavier battle units
minBomberCounter = 0
maxBomberCounter = 16
baseBomberCounter = 2
breakthroughBomberCounter = 8 -- build atomic bombers or air fortresses

-- raid counter works backwards: it determines the number of raiders to build
-- if it reaches minRaidCounter, none are built
minRaidCounter = 0
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

-- how much metal to assume features with these strings in their names have
local baseFeatureMetal = { rock = 30, heap = 80, wreck = 150 }