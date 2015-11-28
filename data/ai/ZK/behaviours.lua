
shard_include( "taskqueues" )
shard_include( "taskqueuebehaviour" )
shard_include( "attackerbehaviour" )
shard_include( "assistbehaviour" )

behaviours = {
	commbasic = {
		TaskQueueBehaviour,
	},
}

function defaultBehaviours(unit)
	b = {}
	u = unit:Internal()
	table.insert(b, BootBehaviour )
	if u:Name() == "armnanotc" then
		table.insert(b,AssistBehaviour)
	else
		if u:CanBuild() then
			table.insert(b,TaskQueueBehaviour)

		else
			if IsAttacker(unit) then
				table.insert(b,AttackerBehaviour)
			end
		end
	end
	return b
end
