require "common"

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
    self.level = unitTable[self.name].techLevel
    self:KeepFactoryLanesClear()
end

function FactoryRegisterBehaviour:UnitCreated(unit)

end

function FactoryRegisterBehaviour:UnitIdle(unit)

end

function FactoryRegisterBehaviour:Update()
	-- don't add factories to factory location table until they're done
	if not self.finished then
		local f = game:Frame()
		if f % 60 == 0 then
			if self.unit ~= nil then
				local unit = self.unit:Internal()
				if unit ~= nil then
					if not unit:IsBeingBuilt() then
						self:Register()
						self.finished = true
					end
				end
			end
		end
	end
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
			self:Unregster()
		end
	end
end

function FactoryRegisterBehaviour:Unregster()
	ai.factories = ai.factories - 1
	local un = self.name
    local level = self.level
   	EchoDebug("factory " .. un .. " level " .. level .. " unregistering")
   	ai.buildsitehandler:DoBuildRectangleByUnitID(self.id)
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
	if ai.factoriesAtLevel[level] == nil then
		ai.factoriesAtLevel[level] = {}
	end
	table.insert(ai.factoriesAtLevel[level], self)
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
end

function FactoryRegisterBehaviour:KeepFactoryLanesClear()
	local sides = factoryExitSides[self.name]
 	if sides ~= nil and sides ~= 0 then
	    -- tell the build handler not to build where the units exit
	    if sides == 1 or sides == 3 then
	    	ai.buildsitehandler:DontBuildRectangle(self.position.x-80, self.position.z, self.position.x+80, self.position.z+240, self.id)
	   	elseif sides == 2 or sides == 4 then
	    	ai.buildsitehandler:DontBuildRectangle(self.position.x-80, self.position.z-240, self.position.x+80, self.position.z+240, self.id)
	    end
	    if sides == 3 or sides == 4 then
	    	ai.buildsitehandler:DontBuildRectangle(self.position.x-120, self.position.z-50, self.position.x+120, self.position.z+50, self.id)
		end
	end
end