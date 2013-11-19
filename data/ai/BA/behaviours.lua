require "taskqueues"
require "taskqueuebehaviour"
require "attackerbehaviour"
require "raiderbehaviour"
require "bomberbehaviour"
require "runfromattack"
require "mexupgradebehaviour"
require "assistbehaviour"
require "reclaimbehaviour"
require "defendbehaviour"
require "factoryregisterbehaviour"
require "scoutbehaviour"
require "antinukebehaviour"
require "nukebehaviour"
require "bombardbehaviour"
require "exitfactorybehaviour"
require "countbehaviour"
require "unitlists"
require "unittable"

behaviours = {
	cornanotc = {
		AssistBehaviour,
		CountBehaviour,
	},
	armnanotc = {
		AssistBehaviour,
		CountBehaviour,
	},
	corfmd = {
		AntinukeBehaviour,
		CountBehaviour,
	},
	armamd = {
		AntinukeBehaviour,
		CountBehaviour,
	},
	corsilo = {
		NukeBehaviour,
		CountBehaviour,
	},
	armsilo = {
		NukeBehaviour,
		CountBehaviour,
	},
	corint = {
		BombardBehaviour,
		CountBehaviour,
	},
	armbrtha = {
		BombardBehaviour,
		CountBehaviour,
	},
}


function defaultBehaviours(unit)
	local b = {}
	local u = unit:Internal()
	local un = u:Name()

	-- keep track of how many of each kind of unit we have
	table.insert(b, CountBehaviour)

	if unitTable[un].isBuilding then
		table.insert(b, RunFromAttackBehaviour)
	elseif unitTable[un].mtype ~= "air" and not commanderList[un] then
		-- non-air mobile units need to not get stuck in the factory
		table.insert(b, ExitFactoryBehaviour)
	end

	if u:CanBuild() then
		-- game:SendToConsole(u:Name() .. " can build")
		-- moho engineer doesn't need the queue!
		if advConList[un] then
			-- game:SendToConsole(u:Name() .. " is advanced construction unit")
			-- half advanced engineers upgrade mexes instead of building things
			if ai.advCons == nil then ai.advCons = 0 end
			if ai.advCons == 0 then
				-- game:SendToConsole(u:Name() .. " taskqueuing")
				table.insert(b, MexUpgradeBehaviour)
				ai.advCons = 1
			else
				-- game:SendToConsole(u:Name() .. " mexupgrading")
				ai.advCons = 0
			end
			table.insert(b,TaskQueueBehaviour)
			table.insert(b, RunFromAttackBehaviour)
		else
			table.insert(b,TaskQueueBehaviour)
			if unitTable[un].isBuilding then
				table.insert(b, FactoryRegisterBehaviour)
				-- game:SendToConsole("factory register behaviour")
			else
				table.insert(b, AssistBehaviour)
				table.insert(b, ReclaimBehaviour)
				table.insert(b, RunFromAttackBehaviour)
			end
		end
	elseif IsReclaimer(unit) then
		table.insert(b, ReclaimBehaviour)
		table.insert(b, ScoutBehaviour)
		table.insert(b, RunFromAttackBehaviour)
	else
		if IsAttacker(unit) then
			table.insert(b, AttackerBehaviour)
			table.insert(b, DefendBehaviour)
		end
		if IsRaider(unit) then
			table.insert(b, RaiderBehaviour)
			table.insert(b, ScoutBehaviour)
		end
		if IsBomber(unit) then
			table.insert(b, BomberBehaviour)
		end
		if IsScout(unit) then
			table.insert(b, ScoutBehaviour)
			table.insert(b, RunFromAttackBehaviour)
		end
		if IsDefender(unit) then
			table.insert(b, DefendBehaviour)
		end
	end
	
	return b
end
