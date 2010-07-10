FactoryRegisterBehaviour = class(Behaviour)

function FactoryRegisterBehaviour:Init()
	--
end

function FactoryRegisterBehaviour:UnitFinished(unit)
    ai.factories = ai.factories + 1
end

function FactoryRegisterBehaviour:UnitIdle(unit)

end

function FactoryRegisterBehaviour:Update()
	--
end

function FactoryRegisterBehaviour:Activate()
	self.unit:ElectBehaviour()
end

function FactoryRegisterBehaviour:Deactivate()
end

function FactoryRegisterBehaviour:Priority()
	return 0
end

function FactoryRegisterBehaviour:UnitDead(unit)
	ai.factories = ai.factories - 1
end
