shard_include( "behaviour" )
shard_include( "behaviours" )

BehaviourFactory = class(AIBase)

function BehaviourFactory:AddBehaviours(unit)
	if not unit then
		self.game:SendToConsole("Warning: Shard BehaviourFactory:AddBehaviours was asked to provide behaviours to a nil unit")
		return
	end
	-- add behaviours here
	-- unit:AddBehaviour(behaviour)
	local b = behaviours[unit:Internal():Name()]
	if b == nil then
		b = defaultBehaviours(unit, ai)
	end
	for i,behaviour in ipairs(b) do
		t = behaviour( ai, unit )
		t:Init()
		unit:AddBehaviour(t)
	end
end

