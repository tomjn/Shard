UnitHandler = class(Module)


function UnitHandler:Name()
	return "UnitHandler"
end

function UnitHandler:internalName()
	return "unithandler"
end

function UnitHandler:Init()
	self.units = {}
	self.myUnits = {}
	self.behaviourFactory = BehaviourFactory()
	self.behaviourFactory:Init()
end

function UnitHandler:Update()
	for k,v in pairs(self.myUnits) do
		v:Update()
	end
end

function UnitHandler:GameEnd()
	for k,v in pairs(self.myUnits) do
		v:GameEnd()
	end
end

function UnitHandler:UnitCreated(engineunit)
	u = Unit()
	self.units[engineunit:ID()] = u
	u:SetEngineRepresentation(engineunit)
	u:Init()
	if engineunit:Team() == game:GetTeamID() then
		self.myUnits[engineunit:ID()] = u
		self.behaviourFactory:AddBehaviours(u)
	end
	for k,v in pairs(self.myUnits) do
		v:UnitCreated(u)
	end
end

function UnitHandler:UnitBuilt(engineunit)
	local u = self:AIRepresentation(engineunit)
	if u ~= nil then
		for k,v in pairs(self.myUnits) do
			v:UnitBuilt(u)
		end
	end
end

function UnitHandler:UnitDead(engineunit)
	local u = self:AIRepresentation(engineunit)
	if u ~= nil then
		for k,v in pairs(self.myUnits) do
			v:UnitDead(u)
		end
	end
	self.units[engineunit:ID()] = nil
	self.myUnits[engineunit:ID()] = nil
end

function UnitHandler:UnitDamaged(engineunit,attacker)
	local u = self:AIRepresentation(engineunit)
	local a = self:AIRepresentation(attacker)
	for k,v in pairs(self.myUnits) do
		v:UnitDamaged(u,a)
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
		if engineunit:Team() == game:GetTeamID() then
			self.behaviourFactory:AddBehaviours(u)
			self.myUnits[engineUnit:ID()] = u
		end
	end
	return u
end

function UnitHandler:UnitIdle(engineunit)
	local u = self:AIRepresentation(engineunit)
	if u ~= nil then
		for k,v in pairs(self.units) do
			v:UnitIdle(u)
		end
	end
end
