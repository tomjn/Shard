shard_include "common"

FactoryRegisterBehaviour = class(Behaviour)

local DebugEnabled = false


local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("FactoryRegisterBehaviour: " .. inStr)
	end
end

function FactoryRegisterBehaviour:Init()
    self.name = self.unit:Internal():Name()
    self.id = self.unit:Internal():ID()
    self.position = self.unit:Internal():GetPosition() -- factories don't move
    self.exitRect = {
    	x1 = self.position.x - 40,
    	z1 = self.position.z - 40,
    	x2 = self.position.x + 40,
    	z2 = self.position.z + 40,
	}
	self.sides = factoryExitSides[self.name]
    self.level = unitTable[self.name].techLevel
end

function FactoryRegisterBehaviour:UnitBuilt(unit)
	-- don't add factories to factory location table until they're done
	if unit.engineID == self.unit.engineID then
		self.finished = true
		self:Register()
	end
end

function FactoryRegisterBehaviour:UnitCreated(unit)

end

function FactoryRegisterBehaviour:UnitIdle(unit)

end

function FactoryRegisterBehaviour:Update()

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
		if self.finished then
			self:Unregister()
		end
	end
end

function FactoryRegisterBehaviour:Unregister()
	ai.factories = ai.factories - 1
	local un = self.name
    local level = self.level
   	EchoDebug("factory " .. un .. " level " .. level .. " unregistering")
   	for i, factory in pairs(ai.factoriesAtLevel[level]) do
   		if factory == self then
   			table.remove(ai.factoriesAtLevel[level], i)
   			break
   		end
   	end
    local maxLevel = 0
    -- reassess maxFactoryLevel
    for level, factories in pairs(ai.factoriesAtLevel) do
    	if #factories > 0 and level > maxLevel then
    		maxLevel = level
    	end
    end
    ai.maxFactoryLevel = maxLevel
	-- game:SendToConsole(ai.factories .. " factories")
end

function FactoryRegisterBehaviour:Register()
	if ai.factories ~= nil then
		ai.factories = ai.factories + 1
	else
		ai.factories = 1
	end
	-- register maximum factory level
    local un = self.name
    local level = self.level
    EchoDebug("factory " .. un .. " level " .. level .. " registering")
	if ai.factoriesAtLevel[level] == nil then
		ai.factoriesAtLevel[level] = {}
	end
	table.insert(ai.factoriesAtLevel[level], self)
	if level > ai.maxFactoryLevel then
		-- so that it will start producing combat units
		ai.attackhandler:NeedLess(nil, 2)
		ai.bomberhandler:NeedLess()
		ai.bomberhandler:NeedLess()
		ai.raidhandler:NeedMore(nil, 2)
		-- set the current maximum factory level
		ai.maxFactoryLevel = level
	end
	-- game:SendToConsole(ai.factories .. " factories")
end