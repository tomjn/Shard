--[[
 Task Queues!
]]--
math.randomseed( os.time() )
math.random(); math.random(); math.random()

taskqueues = {
	bflagshipbase = {
		
		"bengineer1",
		"bengineer1",
		"bengineer1",
		"bengineer1",
		"bengineer1",
		"bengineer1",
		"breztank",
		},
	bengineer1 = {
			
		"bpowerplant",
		"bmex",
		"bpowerplant",
		"bmex",
		"bmex",
		(function()
			local r = math.random(0,5)
			if r == 0 then
				return "bmechfactory"
			elseif r == 1 then
				return "btankfactory"
			elseif r == 2 then
				return "bairport"
			elseif r == 3 then
				return "bsubpens"
			elseif r == 4 then
				return "bsupportfactory"
			elseif r == 5 then
				return "bshipyard"
				
			end												
			
		end),
		
		"bpowerplant",
		"bmex",
		"bradartower",
		"bpowerplant",
		"bairturret",
		"bairturret",
		"bpowerplant",
		"blandturret",
		"blandturret",
		"bnuclearpower",
		"bpowerplant",
		"bmex",
		"blandnavalturret",
		"bmex",
		"bpowerplant",
		"bnuclearpower",
		"blandnavalturret",
		"bairturret",
		"bpowerplant",
		},
	
	bmechfactory = {
	
		"bbasicmech",
		"bbasicmech",
		"bsnipermech",
		"bamphmech",
		"bantitankmech",
		"bamphmech",
		"bbasicmech",
		"bantitankmech",
		"bbasicmech",
		"bsiegemech",
		"bsiegemech",
		"bflyingmech",
		},
		
	btankfactory = {
	
		"bmissiletank",
		"bradartank",	
		"bassaulttank",
		"bassaulttank",
		"bassaulttank",
		"bsiegeartillery",
		"bmissiletank",
		"bsiegeartillery",
		"bsiegeartillery",
		"bassaulttank",
		"bsiegeartillery",
		"bsiegeartillery",
		"bmissiletank",
		"bmissiletank",
		"bsiegeartillery",
		"bassaulttank",
		"bassaulttank",
		"bassaulttank",
		"bsiegeartillery",
		"bsiegeartillery",
		},

bairport = {

		"bradarplane",
		"bfighter",
		"bfighter",
		"brocketplane",
		"brocketplane",
		"bradarplane",
		"brocketplane",
		"brocketplane",
		"bradarplane",
		"bfighter",
		"bfighter",
		"bbomber",
		"bbomber",
		"bbomber",		
		},	

bsubpens = {
		
		"bseaengineer1",
		"bseaengineer1",
		"bamphmech",
		"bamphmech",
		"bsubmarine",
		"baasub",
		"baasub",
		},
		
bsupportfactory = {
		
		"bmetaltruck",
		"bmetaltruck",
		"benergytruck",
		"benergytruck",
		"bengineer1",
		"bengineer1",
		"breztank",
		},
		
bshipyard = {
		
		"bseaengineer1",
		"bseaengineer1",
		"bmetalsupplyboat",
		"bmetalsupplyboat",
		"benergysupplyboat",
		"benergysupplyboat",
		"bbattleship",
		"bartilleryship",
		"brocketbattleship",
		"bbattleship",
		"baaship",
		"bbattleship",
		"bradarship",
		
		},
		
		bseaengineer1 = {
		
		"bseapowerplant",
		"bseapowerplant",
		"bseamex",
		"bsearadartower",
		"bshipyard",
		"bsubpens",
		"btorpedoturret",
		"btorpedoturret",
		},
}
