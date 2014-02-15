require "common"

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
	self.mtype = unitTable[self.name].mtype
	for i, name in pairs(raiderList) do
		if name == self.name then
			EchoDebug(self.name .. " is scramble")
			self.scramble = true
			if self.mtype ~= "air" then
				ai.defendhandler:AddScramble(self)
			end
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
	if self.unit == nil then return end
	local unit = self.unit:Internal()
	if unit == nil then return end
	if self.active then
		local f = game:Frame()
		if math.mod(f,60) == 0 then
			if self.target == nil then return end
			local targetPos = self.target.position or BehaviourPosition(self.target.behaviour)
			local safe = ai.defendhandler:DefendeeSafe(self.target)
			if targetPos ~= nil then
				local unitPos = unit:GetPosition()
				local dist = Distance(unitPos, targetPos)
				local behaviour = self.target.behaviour
				local guardDistance = self.target.guardDistance
				if dist > guardDistance + 500 and behaviour ~= nil then
					if self.guarding ~= behaviour.id then
						-- move toward mobile defendees that are far away with guard order
						CustomCommand(self.unit:Internal(), CMD_GUARD, {behaviour.id})
						self.guarding = behaviour.id
					end
				elseif not safe then
					self.guarding = nil
					if dist < guardDistance + 350 then
						-- just keep going after enemies near turtles
					else
						-- move back to the turtle at a slightly more generous distance if we're too far away
						local guardPos = RandomAway(targetPos, guardDistance + 50, false, self.guardAngle)
						unit:Move(guardPos)
					end
				else
					self.guarding = nil
					if dist > guardDistance + 25 or dist < guardDistance - 25 then
						-- keep near mobile units and buildings not yet in danger
						local guardPos = RandomAway(targetPos, guardDistance, false, self.guardAngle)
						unit:Move(guardPos)
					end
				end
			end
		end
		self.unit:ElectBehaviour()
	end
end

function DefendBehaviour:Assign(defendee, angle)
	if defendee == nil then
		self.target = nil
	else
		self.target = defendee
		self.guardAngle = angle or math.random() * twicePi
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
	self.guarding = nil
	ai.defendhandler:AddDefender(self)
	self:SetMoveState()
end

function DefendBehaviour:Deactivate()
	EchoDebug("inactive on "..self.name)
	self.active = false
	self.target = nil
	self.targetPos = nil
	self.guarding = nil
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
		return 40
	end
end

-- set all defenders to roam
function DefendBehaviour:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local floats = api.vectorFloat()
		floats:push_back(MOVESTATE_ROAM)
		thisUnit:Internal():ExecuteCustomCommand(CMD_MOVE_STATE, floats)
	end
end