--[[
Task Queues!
]]--
math.randomseed( os.time() )
math.random(); math.random(); math.random()

taskqueues = {
-- arm units
	armcom = { -- commander
		"armmex",
		"armmex",
		"armsolar",
		"armlab",
		"armmex",
		"armsolar",
		"armllt",
		"armrad",
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armsolar",
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armmex",
		"armllt",
		"armrad",
		"armsolar",
		"armsolar",
		"armsolar",
	},
	armlab = { -- arm kbot lab
		"armck",
		"armck",
		"armck",
		"armpw",
		"armpw",
		"armwar",
		"armrock",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
		"armpw",
	},
	armck = { -- arm construction kbot
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armmex",
		"armllt",
		"armrad",
		"armsolar",
		"armsolar",
		"armsolar",
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armmex",
		"armllt",
		"armlab",
--		"armnanotc", -- nano tower TODO: when build, set to patrol
		"armrad",
		"armadvsol", -- advanced solar
		"armadvsol", -- advanced solar
		"armadvsol", -- advanced solar
		"armalab", -- advanced kbot lab
--		"armnanotc", -- nano tower
--		"armnanotc",  -- nano tower
	},
	armalab = { -- advanced kbot lab
		"armack", -- advanced construction kbot
		"armzeus",
		"armzeus",
		"armzeus",
		"armsnipe", --sniper
		"armaak", -- anti air
		"armmark", -- radar
		"armaser", -- radar jammer
		"armaak", -- anti air
		"armzeus",
		"armzeus",
		"armzeus",
		"armaak", -- anti air
		"armfboy", -- heavy plasma kbot
		"armfast",
		"armfast",
		"armfast",
		"armfast",
		"armfast",
	},
	armack = { -- advanced construction kbot
		"armfus", -- fusion reactor
		"armmmkr", -- moho energy converter
		"armmmkr", -- moho energy converter
	},
-- core units
	corcom = {
		"corsolar",
		"cormex",
		"corllt",
		"cormex",
		"cormex",
		--"corlab",
		(function()
			local r = math.random(0,2)
			if r == 0 then
				return "corlab"
			elseif r == 1 then
				return "corvp"
			else
				return "corap"
			end
		end),
		"corsolar",
		"corllt",
		"corrad",
		"corsolar",
		"corllt",
		"corsolar",
		"cormakr",
		"corsolar",
		"cormex",
		"corllt",
		"cormex",
		"corsolar",
		"cormakr",
		"corllt",
		"cornanotc",
		"corsolar",
	},
	corck = {
		"corsolar",
		"cormex",
		"cormex",
		"corllt",
		"corrad",
		"corllt",
		"corsolar",
		"corllt",
		"corsolar",
		"cormex",
		"corhlt",
		"cornanotc",
		"corllt",
	},

	corca = {
		"corsolar",
		"cormex",
		"corsolar",
		"cormex",
		"cormex",
		"corllt",
		"corrad",
		"corllt",
		"corsolar",
		"corsolar",
		"corllt",
		"corsolar",
		"cormex",
		"corhlt",
		"cornanotc",
		"corllt",
		"corsolar",
	},

	corcv = {
		"corsolar",
		"cormex",
		"corsolar",
		"cormex",
		"cormex",
		"corllt",
		"corrad",
		"corllt",
		"corsolar",
		"corsolar",
		"corllt",
		"corsolar",
		"cormex",
		"corhlt",
		"cornanotc",
		"corllt",
		"corsolar",
	},

	cormlv = {
		"cormine1",
		"cormine1",
		"cormine1",
		"cormine1",
		"cormine2",
		"cormine3",
	},
	corlab = {
		"corck",
		"corck",
		"corak",
		"corak",
		"corak",
		"corak",
		"corck",
		"corak",
		"corck",
		"corthud",
		"corthud",
		"corthud",
	},
	corvp = {
		"corcv",
		"cormlv",
		"corgator",
		"corgator",
		"corgator",
		"corraid",
		"corcv",
		"corraid",
		"corraid",
		"corgator",
		"corraid",
		"corraid",
		"corcv",
		"corcv",
		"corraid",
		"corgator",
		"corgator",
		"corgator",
		"corraid",
		"corraid",
	},
	corap = {
		"corca",
		"corveng",
		"corveng",
		"bladew",
		"bladew",
		"corca",
		"bladew",
		"bladew",
		"corca",
		"corveng",
		"corveng",
		"corshad",
		"corshad",
		"corshad",
	},
}
