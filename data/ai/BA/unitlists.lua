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
	corvp = {"veh", "amp"},
	armvp = {"veh", "amp"},
	coralab = {"bot"},
	coravp = {"veh", "amp"},
	corhp = {"hov"},
	armhp = {"hov"},
	corfhp = {"hov"},
	armfhp = {"hov"},
	armalab = {"bot"},
	armavp = {"veh", "amp"},
	coraap = {"air"},
	armaap = {"air"},
	corplat = {"air"},
	armplat = {"air"},
	corsy = {"shp", "sub"},
	armsy = {"shp", "sub"},
	corasy = {"shp", "sub"},
	armasy = {"shp", "sub"},
	csubpen = {"sub", "amp"},
	asubpen = {"sub", "amp"},
	corgant = {"bot"},
	armshltx = {"bot"},
}

-- for calculating what factories to build
-- higher values mean more effecient
mobilityEffeciencyMultiplier = {
	veh = 1,
	shp = 1,
	bot = 0.9,
	sub = 0.9,
	hov = 0.7,
	amp = 0.4,
	air = 0.55,
}

-- for calculating what factories to build
-- higher values mean slower
mobilitySlowMultiplier = {
	veh = 1,
	shp = 1,
	sub = 1.3,
	bot = 1.3,
	hov = 0.75,
	amp = 1.5,
	air = 0.25,
}

factoryExitSides = {
	corap = 0,
	armap = 0,
	corlab = 2,
	armlab = 2,
	corvp = 1,
	armvp = 1,
	coralab = 3,
	coravp = 1,
	corhp = 2,
	armhp = 2,
	corfhp = 2,
	armfhp = 2,
	armalab = 2,
	armavp = 2,
	coraap = 0,
	armaap = 0,
	corplat = 0,
	armplat = 0,
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

-- priorities of things to defend that can't be accounted for by the formula in turtlehandler
turtleList = {
	cormakr = 0.5,
	armmakr = 0.5,
	corfmkr = 0.5,
	armfmkr = 0.5,
	cormmkr = 4,
	armmmkr = 4,
	coruwmmm = 4,
	armuwmmm = 4,
	corestor = 0.5,
	armestor = 0.5,
	cormstor = 0.5,
	armmstor = 0.5,
	coruwes = 0.5,
	armuwes = 0.5,
	coruwms = 0.5,
	armuwms = 0.5,
	coruwadves = 2,
	armuwadves = 2,
	coruwadvms = 2,
	armuwadvms = 2,
}

-- factories that can build advanced construction units (i.e. moho mines)
advFactories = {
	coravp = 1,
	coralab = 1,
	corasy = 1,
	coraap = 1,
	corplat = 1,
	armavp = 1,
	armalab = 1,
	armasy = 1,
	armaap = 1,
	armplat = 1,
}

-- experimental factories
expFactories = {
	corgant = 1,
	armshltx = 1,
}

-- leads to experimental
leadsToExpFactories = {
	corlab = 1,
	armlab = 1,
	coralab = 1,
	armalab = 1,
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
	"armsfig",
	"corveng",
	"corvamp",
	"corsfig",
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
	corfink = 1,
	armpeep = 1,
	corfav = 1,
	armfav = 1,
	armflea = 1,
	corawac = 1,
	armawac = 1,
	corpt = 1,
	armpt = 1,
	corhunt = 1,
	armsehak = 1,
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
	armsy = 1,
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
	"corcrw",
	-- subs
	"corsub",
	"armsub",
	"armsubk",
	"corsubk",
}

raiderDisarms = {
	bladew = 1,
}

-- units in this list are bombers or torpedo bombers
bomberList = {
	corshad = 1,
	armthund = 1,
	corhurc = 2,
	armpnix = 2,
	armcybr = 3,
	corsb = 2,
	armsb = 2,
	cortitan = 2,
	armlance = 2,
	corseap = 2,
	armseap = 2,
}

seaplaneConList = {
	corcsa = 1,
	armcsa = 1,
}

-- minimum, maximum, starting point units required to attack, bomb
minAttackCounter = 8
maxAttackCounter = 30
baseAttackCounter = 15
breakthroughAttackCounter = 16 -- build heavier battle units
siegeAttackCounter = 20 -- build siege units
minBattleCount = 4 -- how many battle units to build before building any breakthroughs, even if counter is too high
minBomberCounter = 0
maxBomberCounter = 16
baseBomberCounter = 2
breakthroughBomberCounter = 8 -- build atomic bombers or air fortresses

-- raid counter works backwards: it determines the number of raiders to build
-- if it reaches minRaidCounter, none are built
minRaidCounter = 0
maxRaidCounter = 8
baseRaidCounter = 5

-- how many mobile con units of one type is allowed
ConUnitPerTypeLimit = 4 --max(map:SpotCount() / 10, 2)
ConUnitAdvPerTypeLimit = 4

-- Taskqueuebehaviour was modified to skip this name
DummyUnitName = "skipthisorder"

-- Taskqueuebehaviour was modified to use this as a generic "build me a factory" order
FactoryUnitName = "buildfactory"

-- this unit is used to check for underwater metal spots
UWMetalSpotCheckUnit = "coruwmex"

-- for non-lua only; tests build orders of these units to determine mobility there
-- multiple units for one mtype function as OR
mobUnitNames = {
	veh = {"corcv", "armllt"},
	bot = {"corck", "armeyes"},
	amp = {"cormuskrat"},
	hov = {"corsh", "armfdrag"},
	shp = {"corcs"},
	sub = {"coracsub"},
}

-- for ShardSpringLua only; tests move orders of these units to determine mobility there
mobUnitExampleName = {
	veh = "armcv",
	bot = "armck",
	amp = "armbeaver",
	hov = "armch",
	shp = "armcs",
	sub = "armacsub"
}

-- side names
CORESideName = "core"
ARMSideName = "arm"

-- how much metal to assume features with these strings in their names have
baseFeatureMetal = { rock = 30, heap = 80, wreck = 150 }