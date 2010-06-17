
require "taskqueues"
require "taskqueuebehaviour"
require "attackerbehaviour"
require "missingfactorybehaviour"
require "engineerturretbehaviour"
require "autoreclaimbehaviour"

behaviours = {
	--eorb = {
	--	AutoReclaimBehaviour,
	--},
	eengineer5 = {
		TaskQueueBehaviour,
		MissingFactoryBehaviour,
		EngineerTurretBehaviour,
	},
	eamphibengineer = {
		TaskQueueBehaviour,
		MissingFactoryBehaviour,
		EngineerTurretBehaviour,
	},
	eairengineer = {
		TaskQueueBehaviour,
		MissingFactoryBehaviour,
		EngineerTurretBehaviour,
	},
	eallterrengineer = {
		TaskQueueBehaviour,
		MissingFactoryBehaviour,
		EngineerTurretBehaviour,
	},
}

function defaultBehaviours(unit)
	b = {}
	
	u = unit:Internal()
	if u:CanBuild() then
		table.insert(b,TaskQueueBehaviour)
		if u:CanMove() then
			local utype = game:GetTypeByName("ebasefactory")
			if u:CanBuild(utype) then
				table.insert(b,MissingFactoryBehaviour)
			end
			utype = game:GetTypeByName("elightturret2")
			if u:CanBuild(utype) then
				table.insert(b,EngineerTurretBehaviour)
			end
		end
	else
		if IsAttacker(unit) then
			table.insert(b,AttackerBehaviour)
		end
	end
	
	return b
end
