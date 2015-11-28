shard_include( "behaviour" )
BehaviourFactory = class(AIBase)

shard_include( "behaviours" )
function BehaviourFactory:Init()
	--
end

function BehaviourFactory:AddBehaviours(unit)
	if unit == nil then
		return
	end
	-- add behaviours here
	-- unit:AddBehaviour(behaviour)
	local b = behaviours[unit:Internal():Name()]
	if b == nil then
		b = defaultBehaviours(unit)
	end
	for i,behaviour in ipairs(b) do
		t = behaviour()
		t:SetUnit(unit)
		t:Init()
		unit:AddBehaviour(t)
	end
end

