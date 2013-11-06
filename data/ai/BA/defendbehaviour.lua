require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("DefendBehaviour: " .. inStr)
	end
end

local CMD_GUARD = 25
local CMD_MOVE_STATE = 50
local MOVESTATE_ROAM = 2

DefendBehaviour = class(Behaviour)

-- not does it defend, but is it a dedicated defender
function IsDefender(unit)
	for i,name in ipairs(defenderList) do
		if name == unit:Internal():Name() then
			return true
		end
	end
	return false
end

function DefendBehaviour:Init()
	self.active = false
	self.target = nil
	self.name = self.unit:Internal():Name()
	-- keeping track of how many of each type of unit
	EchoDebug("DefendBehaviour: added to unit "..self.name)
end

function DefendBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("defender " .. self.name .. " died")
		ai.defendhandler:RemoveDefender(self)
	end
end

function DefendBehaviour:UnitIdle(unit)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		self.unit:ElectBehaviour()
	end
end

function DefendBehaviour:Update()
	local f = game:Frame()
	if math.mod(f,60) == 0 then
		if self.active then
			if self.target ~= nil then
				local tid = self.target:ID()
				if self.defending ~= tid then
					local floats = api.vectorFloat()
	    			floats:push_back(tid)
					self.unit:Internal():ExecuteCustomCommand(CMD_GUARD, floats)
					self.defending = tid
				end
			end
		end
		self.unit:ElectBehaviour()
	end
end

function DefendBehaviour:Assign(unit)
	self.target = unit
end

function DefendBehaviour:Activate()
	EchoDebug("DefendBehaviour: active on unit "..self.unit:Internal():Name())
	self.active = true
	self.target = nil
	self.defending = nil
	ai.defendhandler:AddDefender(self)
	self:SetMoveState()
end

function DefendBehaviour:Deactivate()
	self.active = false
	self.target = nil
	self.defending = nil
	ai.defendhandler:RemoveDefender(self)
end

function DefendBehaviour:Priority()
	return 50
end

-- this will issue Raom to all defenders
function DefendBehaviour:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local floats = api.vectorFloat()
		floats:push_back(MOVESTATE_ROAM)
		thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
	end
end