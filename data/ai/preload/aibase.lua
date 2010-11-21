
AIBase = class(function(a)
   --
end)


function AIBase:Init()
end

function AIBase:Update()
end

function AIBase:GameEnd()
end

function AIBase:UnitCreated(unit)
end

function AIBase:UnitBuilt(unit)
end

function AIBase:UnitGiven(unit)
	self:UnitCreated(unit)
	self:UnitBuilt(unit)
end


function AIBase:UnitDead(unit)
end

function AIBase:UnitIdle(unit)
end

function AIBase:UnitDamaged(unit,attacker)
end
