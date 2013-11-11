require "unitlists"

FactoryRegisterBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("FactoryRegisterBehaviour: " .. inStr)
	end
end

function FactoryRegisterBehaviour:Init()
	if ai.factories ~= nil then
		ai.factories = ai.factories + 1
	else
		ai.factories = 1
	end
	-- register maximum factory level
    local un = self.unit:Internal():Name()
    self.name = un
    local level = unitTable[un].techLevel
    if ai.factoriesAtLevel[level] ~= nil then
    	ai.factoriesAtLevel[level] = ai.factoriesAtLevel[level] + 1
    else
		ai.factoriesAtLevel[level] = 1
	end
	if level > ai.maxFactoryLevel then
		-- so that it will start producing combat units
		ai.attackhandler:NeedLess()
		ai.attackhandler:NeedLess()
		ai.bomberhandler:NeedLess()
		ai.bomberhandler:NeedLess()
		ai.raidhandler:NeedMore()
		ai.raidhandler:NeedMore()
		-- set the current maximum factory level
		ai.maxFactoryLevel = level
	end
	-- game:SendToConsole(ai.factories .. " factories")
	self.unit:ElectBehaviour()
end

function FactoryRegisterBehaviour:UnitCreated(unit)

end

function FactoryRegisterBehaviour:UnitIdle(unit)

end

function FactoryRegisterBehaviour:Update()
	--
end

function FactoryRegisterBehaviour:Activate()

end

function FactoryRegisterBehaviour:Deactivate()
end

function FactoryRegisterBehaviour:Priority()
	return 0
end

function FactoryRegisterBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("factory " .. self.name .. " died")
		ai.factories = ai.factories - 1
		local un = self.name
	    local level = unitTable[un].techLevel
	   	EchoDebug("factory " .. un .. " level " .. level .. " died")
	    ai.factoriesAtLevel[level] = ai.factoriesAtLevel[level] - 1
	    local maxLevel = 0
	    -- assess maxFactoryLevel
	    for level, number in pairs(ai.factoriesAtLevel) do
	    	if number > 0 and level > maxLevel then
	    		maxLevel = level
	    	end
	    end
	    ai.maxFactoryLevel = maxLevel
		-- game:SendToConsole(ai.factories .. " factories")
	end
end
