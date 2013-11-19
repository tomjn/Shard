require "unitlists"

CountBehaviour = class(Behaviour)

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("CountBehaviour: " .. inStr)
	end
end

function CountBehaviour:Init()
	self.finished = false
    self.name = self.unit:Internal():Name()
    self.id = self.unit:Internal():ID()
    if unitTable[self.name].isBuilding then
   		self.position = self.unit:Internal():GetPosition() -- buildings don't move
   	end
    self.level = unitTable[self.name].techLevel
	if ai.nameCount[self.name] == nil then
		ai.nameCount[self.name] = 1
	else
		ai.nameCount[self.name] = ai.nameCount[self.name] + 1
	end
	EchoDebug(ai.nameCount[self.name] .. " " .. self.name .. " created")
	ai.lastNameCreated[self.name] = game:Frame()
	self.unit:ElectBehaviour()
end

function CountBehaviour:UnitCreated(unit)

end

function CountBehaviour:UnitIdle(unit)

end

function CountBehaviour:Update()
	-- find out when it finished building
	if not self.finished then
		local f = game:Frame()
		if f % 30 == 0 then
			if self.unit ~= nil then
				local unit = self.unit:Internal()
				if unit ~= nil then
					if not unit:IsBeingBuilt() then
						if ai.nameCountFinished[self.name] == nil then
							ai.nameCountFinished[self.name] = 1
						else
							ai.nameCountFinished[self.name] = ai.nameCountFinished[self.name] + 1
						end
						ai.lastNameFinished[self.name] = f
						EchoDebug(ai.nameCountFinished[self.name] .. " " .. self.name .. " finished")
						self.finished = true
					end
				end
			end
		end
	end
end

function CountBehaviour:Activate()

end

function CountBehaviour:Deactivate()
end

function CountBehaviour:Priority()
	return 0
end

function CountBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		ai.nameCount[self.name] = ai.nameCount[self.name] - 1
		if self.finished then
			ai.nameCountFinished[self.name] = ai.nameCountFinished[self.name] - 1
		end
	end
end