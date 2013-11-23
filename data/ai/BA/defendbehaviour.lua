require "unitlists"

local DebugEnabled = false

local function EchoDebug(inStr)
	if DebugEnabled then
		game:SendToConsole("DefendBehaviour: " .. inStr)
	end
end

local CMD_GUARD = 25
local CMD_PATROL = 15
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
	self.name = self.unit:Internal():Name()
	for i, name in pairs(raiderList) do
		if name == self.name then
			EchoDebug(self.name .. " is scramble")
			self.scramble = true
			ai.defendhandler:AddScramble(self)
			break
		end
	end
	-- keeping track of how many of each type of unit
	EchoDebug("added to unit "..self.name)
end

function DefendBehaviour:UnitDead(unit)
	if unit.engineID == self.unit.engineID then
		-- game:SendToConsole("defender " .. self.name .. " died")
		if self.scramble then
			ai.defendhandler:RemoveScramble(self)
			if self.scrambled then
				ai.defendhandler:RemoveDefender(self)
			end
		else
			ai.defendhandler:RemoveDefender(self)
		end
	end
end

function DefendBehaviour:UnitIdle(unit)
	if unit:Internal():ID() == self.unit:Internal():ID() then
		self.unit:ElectBehaviour()
	end
end

function DefendBehaviour:Update()
	if self.active then
		local f = game:Frame()
		if math.mod(f,60) == 0 then
			if self.target ~= nil then
				local tid = self.target:ID()
				if self.defending ~= tid then
					local floats = api.vectorFloat()
	    			floats:push_back(tid)
					self.unit:Internal():ExecuteCustomCommand(CMD_GUARD, floats)
					self.defending = tid
				end
			elseif self.targetPos ~= nil then
				if self.defending ~= self.targetPos then
					local point, patrolPoint = RandomAway(self.targetPos, 100, true)
					EchoDebug(point.x .. ", " .. point.z .. "  " .. patrolPoint.x .. ", " .. patrolPoint.z)
					self.unit:Internal():Move(point)
					local floats = api.vectorFloat()
					-- populate with x, y, z of the position
					floats:push_back(patrolPoint.x)
					floats:push_back(patrolPoint.y)
					floats:push_back(patrolPoint.z)
					self.unit:Internal():ExecuteCustomCommand(CMD_PATROL, floats)
					self.defending = self.targetPos
				end
			end
		end
		self.unit:ElectBehaviour()
	end
end

function DefendBehaviour:Assign(defendee)
	if defendee == nil then
		self.target = nil
		self.targetPos = nil
	else
		self.target = defendee.unit
		self.targetPos = defendee.position
	end
end

function DefendBehaviour:Scramble()
	EchoDebug(self.name .. " scrambled")
	self.scrambled = true
	self.unit:ElectBehaviour()
end

function DefendBehaviour:Unscramble()
	EchoDebug(self.name .. " unscrambled")
	self.scrambled = false
	self.unit:ElectBehaviour()
end

function DefendBehaviour:Activate()
	EchoDebug("active on "..self.name)
	self.active = true
	self.target = nil
	self.targetPos = nil
	self.defending = nil
	ai.defendhandler:AddDefender(self)
	self:SetMoveState()
end

function DefendBehaviour:Deactivate()
	EchoDebug("inactive on "..self.name)
	self.active = false
	self.target = nil
	self.targetPos = nil
	self.defending = nil
	ai.defendhandler:RemoveDefender(self)
end

function DefendBehaviour:Priority()
	if self.scramble then
		if self.scrambled then
			return 110
		else
			return 0
		end
	else
		return 50
	end
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