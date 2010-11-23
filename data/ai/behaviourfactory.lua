require "behaviour"
BehaviourFactory = class(AIBase)

require "behaviours"
function BehaviourFactory:Init()
	
end

function BehaviourFactory:AddBehaviours(unit)
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

