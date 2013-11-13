require "unitlists"

FactoryRegisterBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("FactoryRegisterBehaviour: " .. inStr)
	end
end

function FactoryRegisterBehaviour:RegisterFactory()
	if ai.factories ~= nil then
		ai.factories = ai.factories + 1
	else
		ai.factories = 1
	end
	-- register maximum factory level
    local un = self.name
    local level = self.level
    if ai.factoriesAtLevel[level] ~= nil then
    	ai.factoriesAtLevel[level] = ai.factoriesAtLevel[level] + 1
    else
		ai.factoriesAtLevel[level] = 1
	end
	if ai.factoryLocationsAtLevel[level] == nil then
		ai.factoryLocationsAtLevel[level] = {}
	end
	table.insert(ai.factoryLocationsAtLevel[level], {position = self.position, uid = self.id})
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

function FactoryRegisterBehaviour:Init()
    self.name = self.unit:Internal():Name()
    self.id = self.unit:Internal():ID()
    self.position = self.unit:Internal():GetPosition() -- factories don't move
    self.level = unitTable[self.name].techLevel
    --[[
    if factoryExitSides[self.name] ~= nil and factoryExitSides[self.name] ~= 0 then
	    -- inform the build handler not to build where the units exit
	    local nobuild = api.Position()
	    nobuild.x = self.position.x
	    nobuild.z = self.position.z + 150
	    nobuild.y = self.position.y
	    ai.buildsitehandler:DontBuildHere(nobuild, 75)
	    if factoryExitSides[self.name] == 2 then
	    	nobuild.z = self.position.z - 150
	    	ai.buildsitehandler:DontBuildHere(nobuild, 75)
	    elseif factoryExitSides[self.name] == 3 or factoryExitSides[self.name] == 4 then
	    	nobuild.z = self.position.z
	    	nobuild.x = self.position.x - 80
	    	ai.buildsitehandler:DontBuildHere(nobuild, 40)
	    	nobuild.x = self.position.x + 80
	    	ai.buildsitehandler:DontBuildHere(nobuild, 40)
	    	if factoryExitSides[self.name] == 4 then
	    		nobuild.x = self.position.x
	    		nobuild.z = self.position.z - 80
	    		ai.buildsitehandler:DontBuildHere(nobuild, 40)
	    	end
	    end
	end
	]]--
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
						self:RegisterFactory()
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
			ai.factories = ai.factories - 1
			local un = self.name
		    local level = self.level
		   	EchoDebug("factory " .. un .. " level " .. level .. " died")
		   	if ai.factoryLocationsAtLevel[level] ~= nil then
			   	for i, location in pairs(ai.factoryLocationsAtLevel[level]) do
			   		if location.uid == self.id then
			   			table.remove(ai.factoryLocationsAtLevel, i)
			   			break
			   		end
			   	end
			end
		    ai.factoriesAtLevel[level] = ai.factoriesAtLevel[level] - 1
		    local maxLevel = 0
		    -- reassess maxFactoryLevel
		    for level, number in pairs(ai.factoriesAtLevel) do
		    	if number > 0 and level > maxLevel then
		    		maxLevel = level
		    	end
		    end
		    ai.maxFactoryLevel = maxLevel
			-- game:SendToConsole(ai.factories .. " factories")
		end
	end
end
