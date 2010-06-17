--[[
 Task Queues!
]]--

local restless = {
	"tc_metalextractor_lvl1",
	"tc_metalextractor_lvl1",
	"tc_soulstone",
	"tc_soulstone",
	"tc_metalextractor_lvl1",
	"tc_metalextractor_lvl1",
	"tc_defender",
	"tc_soulstone",
	"tc_pyramid_ai",
	"tc_defender",
	"tc_soulstone",
	"tc_soulstone",
	"tc_damnedportal_ai",
	"tc_defender",
}

local lich = {
	"tc_metalextractor_lvl2",
	"tc_soulcage",
	"tc_metalextractor_lvl2",
	"tc_soulcage",
	"tc_mancubus",	
	"tc_cursedhand",
	"tc_mancubus",	
	"tc_cursedhand",	
	"tc_altar",
}


local pyramidAI = {
	"tc_restless",
	"tc_restless",
	"tc_skeleton",
	"tc_skeleton",
	"tc_mage",
	"tc_skeleton",
	"tc_gunner",
	"tc_gunner",
	"tc_gunner",
	"tc_enforcer",
	"tc_enforcer",
	"tc_skeleton",
	"tc_witch",
}

local damnedportalAI = {
	"tc_lich_ai",
	"tc_lich_ai",	
	"tc_rictus",
	"tc_rictus",
	"tc_mermeoth",
	"tc_agares",
	"tc_mancubus",
	"tc_mancubus",
	"tc_mancubus",
	"tc_belial",
	"tc_purgatory_ai",
}

local altar = {
	"tc_dragon",
}

taskqueues = {
	tc_damnedportal_ai = damnedportalAI,
	tc_restless = restless,
	tc_lich_ai = lich,	
	tc_pyramid_ai = pyramidAI,
	tc_altar = altar,
}
