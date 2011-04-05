UnitHandler = class(Module)


function UnitHandler:Name()
	return "UnitHandler"
end

function UnitHandler:internalName()
	return "unithandler"
end

function UnitHandler:Init()
	self.units = {}
	self.behaviourFactory = BehaviourFactory()
	self.behaviourFactory:Init()
end

function UnitHandler:Update()
	for k,v in pairs(self.units) do
		v:Update()
	end
end

function UnitHandler:GameEnd()
	for k,v in pairs(self.units) do
		v:GameEnd()
	end
end

function UnitHandler:UnitCreated(engineunit)
	u = Unit()
	self.units[engineunit:ID()] = u
	u:SetEngineRepresentation(engineunit)
	u:Init()
	self.behaviourFactory:AddBehaviours(u)
	for k,v in pairs(self.units) do
		v:UnitCreated(u)
	end
end

function UnitHandler:UnitBuilt(engineunit)
	u = self:AIRepresentation(engineunit)
	for k,v in pairs(self.units) do
		v:UnitBuilt(u)
	end
end

function UnitHandler:UnitDead(unit)
	u = self:AIRepresentation(unit)
	for k,v in pairs(self.units) do
		v:UnitDead(u)
	end
	self.units[unit] = nil
end
function UnitHandler:UnitDamaged(unit,attacker)
	u = self:AIRepresentation(unit)
	a = self:AIRepresentation(attacker)
	for k,v in pairs(self.units) do
		v:UnitDamaged(u)
	end
end

function UnitHandler:AIRepresentation(engineUnit)
	if engineUnit == nil then
		return nil
	end
	local unittable = self.units
	local u = unittable[engineUnit:ID()]
	if u == nil then
		u = Unit()
		self.units[engineUnit:ID()] = u
		u:SetEngineRepresentation(engineUnit)
		u:Init()
		self.behaviourFactory:AddBehaviours(u)
	end
	return u
end

function UnitHandler:UnitIdle(unit)
	u = self:AIRepresentation(unit)
	for k,v in pairs(self.units) do
		v:UnitIdle(u)
	end
end
