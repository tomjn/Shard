Behaviour = class(AIBase)

function Behaviour:Init()
end

function Behaviour:Update()
end

function Behaviour:GameEnd()
end

function Behaviour:UnitCreated(unit)
end

function Behaviour:UnitBuilt(unit)
end

function Behaviour:UnitDead(unit)
end

function Behaviour:UnitDamaged(unit,attacker)
end

function Behaviour:UnitIdle(unit)
end

function Behaviour:SetUnit(unit)
	self.unit = unit
end


function Behaviour:IsActive()
	return self.active
end

function Behaviour:Activate()
	--
end

function Behaviour:Deactivate()
	--
end

function Behaviour:Priority()
	return 0
end

function Behaviour:Passive()
	return false
end
