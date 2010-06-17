--[[
 Task Queues!
]]--

math.randomseed( os.time() )
math.random(); math.random(); math.random()

function CoreWindSolar()
	if game:AverageWind() > 10 then
		return "corwind"
	else
		return "corsolar"
	end
end

taskqueues = {
	corcom = {
			
		CoreWindSolar,
		"cormex",
		CoreWindSolar,
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
		"corllt",
		"corrad",
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		"cormex",
		"cormex",
		"cormex",
		"corllt",
		CoreWindSolar,
		},
	corck = {
		CoreWindSolar,
		"cormex",
		CoreWindSolar,
		"cormex",
		"cormex",
		"corllt",
		"corrad",
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		CoreWindSolar,
		"cormex",
		"cormex",
		"cormex",
		"corllt",
		CoreWindSolar,
		},
	armcom = {
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armmex",
		"armlab",
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
		"armrad",
		"armsolar",
		"armsolar",
		"armsolar",
		},
	armck = {
		"armsolar",
		"armmex",
		"armsolar",
		"armmex",
		"armmex",
		"armlab",
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
		"armrad",
		"armsolar",
		"armsolar",
		"armsolar",
		},
	corlab = {
		"corck",
		"corck",
		"corck",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		"corak",
		},
	armlab = {
		"armck",
		"armck",
		"armck",
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
		"armpw",
		"armpw",
		},
}
