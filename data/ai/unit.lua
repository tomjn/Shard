Unit = class(AIBase)

function Unit:SetEngineRepresentation(engineUnit)
	self.engineUnit = engineUnit
end

function Unit:Internal()
	return self.engineUnit
end

function Unit:Init()
	if self.engineUnit == nil then
		game:SendToConsole("nil engineUnit?!")
	end
	self.behaviours = {}
	self.behaviourvalues = {}
end

function Unit:Update()
	for k,v in pairs(self.behaviours) do
		v:Update(unit)
	end
end

function Unit:GameEnd()
	for k,v in pairs(self.behaviours) do
		v:GameEnd(unit)
	end
end

function Unit:UnitCreated(unit)
	for k,v in pairs(self.behaviours) do
		v:UnitCreated(unit)
	end
end

function Unit:UnitBuilt(unit)
	self:ElectBehaviour()
	for k,v in pairs(self.behaviours) do
		v:UnitBuilt(unit)
	end
end

function Unit:UnitDead(unit)
	for k,v in pairs(self.behaviours) do
		v:UnitDead(unit)
	end
	if unit:Internal():ID() == self.engineunit:Internal():ID() then
		for k,v in pairs(self.behaviours) do
			self.behaviours[k] = nil
		end
		self.behaviours = nil
		self.engineUnit = nil
	end
end

function Unit:UnitDamaged(unit,attacker)
	for k,v in pairs(self.behaviours) do
		v:UnitDamaged(unit,attacker)
	end
end

function Unit:UnitIdle(unit)
	for k,v in pairs(self.behaviours) do
		v:UnitIdle(unit)
	end
end

function Unit:AddBehaviour(behaviour)
	table.insert(self.behaviours,behaviour)
end

function Unit:ActiveBehaviour()
	return self.activebeh
end

function Unit:ElectBehaviour()
	local bestbeh = nil
	local bestscore = -1
	if #self.behaviours > 0 then
		for k,v in pairs(self.behaviours) do
			if bestbeh == nil then
				bestbeh = v
				bestscore = v:Priority()
			else
				local score = v:Priority()
				if score > bestscore then
					bestscore = score
					bestbeh = v
				end
			end
		end
		
		if self.activebeh ~= bestbeh then
			if self.activebeh ~= nil then
				self.activebeh:Deactivate()
			end
			self.activebeh = bestbeh
			self.activebeh:Activate()
		end
	end
end
